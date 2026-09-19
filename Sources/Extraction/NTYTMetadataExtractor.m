#import "NTYTMetadataExtractor.h"

#import <YouTubeHeader/YTIElementRenderer.h>

#import "Core/NTYTContentMetadata.h"
#import "NTYTProtobufReader.h"

@interface YTIElementRenderer (NTYTElementDataAccess)
- (NSData * _Nullable)elementData;
@end

static NSErrorDomain const NTYTMetadataExtractorErrorDomain = @"com.whitenightchan.nothankyoutube.extraction";

static NSError *NTYTExtractionError(NSInteger code, NSString *message) {
    return [NSError errorWithDomain:NTYTMetadataExtractorErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: message}];
}

static NSArray<NSNumber *> *NTYTPrimaryVideoPath(void) {
    return @[@1, @168777401, @5, @232954548, @18, @5, @169495254,
             @98150882, @1, @66439850, @1, @66441155, @3, @73080600];
}

static NSArray<NSNumber *> *NTYTRichMetadataVariantAPath(void) {
    return @[@1, @168777401, @5, @232954548, @18, @4, @169495254,
             @462702848, @1, @200453700, @1, @48687757];
}

static NSArray<NSNumber *> *NTYTRichMetadataVariantBPath(void) {
    return @[@1, @168777401, @5, @232954548, @18, @4, @169495254,
             @462702848, @1, @48687757];
}

static NSArray<NSArray<NSNumber *> *> *NTYTRichMetadataPaths(void) {
    return @[
        NTYTRichMetadataVariantAPath(),
        NTYTRichMetadataVariantBPath(),
    ];
}

static NSArray<NSNumber *> *NTYTChannelMetadataPath(void) {
    return @[@1, @168777401, @5, @232954548, @18, @1, @3, @5,
             @169495254, @48687626];
}

static NSString *NTYTExactlyOneString(NSArray<NSString *> *strings, BOOL requireNonEmpty) {
    if (strings.count != 1) {
        return nil;
    }
    NSString *value = strings.firstObject;
    if (requireNonEmpty && value.length == 0) {
        return nil;
    }
    return value;
}

@interface NTYTMetadataExtractionResult ()

@property(nonatomic, readwrite, getter=isSuccess) BOOL success;
@property(nonatomic, strong, readwrite, nullable) NTYTContentMetadata *metadata;
@property(nonatomic, strong, readwrite, nullable) NSError *error;

@end

@implementation NTYTMetadataExtractionResult

+ (instancetype)successWithMetadata:(NTYTContentMetadata *)metadata {
    NTYTMetadataExtractionResult *result = [self new];
    result.success = YES;
    result.metadata = metadata;
    return result;
}

+ (instancetype)failureWithError:(NSError *)error {
    NTYTMetadataExtractionResult *result = [self new];
    result.success = NO;
    result.error = error;
    return result;
}

@end

@implementation NTYTMetadataExtractor

+ (NTYTMetadataExtractionResult *)extractFromElementRenderer:(YTIElementRenderer *)elementRenderer {
    if (!elementRenderer) {
        return [NTYTMetadataExtractionResult failureWithError:
            NTYTExtractionError(1, @"The element renderer is unavailable.")];
    }

    @try {
        id value = [elementRenderer elementData];
        if (![value isKindOfClass:[NSData class]]) {
            return [NTYTMetadataExtractionResult failureWithError:
                NTYTExtractionError(2, @"The elementData value is not safe NSData input.")];
        }
        NSData *data = (NSData *)value;
        NSError *rootError = nil;
        if (![NTYTProtobufReader validateMessageData:data error:&rootError]) {
            return [NTYTMetadataExtractionResult failureWithError:
                rootError ?: NTYTExtractionError(3, @"The elementData root message is malformed.")];
        }

        NSString *resolvedVideoID = nil;
        NSData *primaryMessage = nil;
        NSError *primaryPathError = nil;
        NSArray<NSData *> *primaryMessages =
            [NTYTProtobufReader messagesAtPath:NTYTPrimaryVideoPath()
                                        inData:data
                                         error:&primaryPathError];
        if (primaryMessages.count == 1) {
            primaryMessage = primaryMessages.firstObject;
            NSArray<NSString *> *primaryStrings =
                [NTYTProtobufReader UTF8StringsForDirectField:1
                                                    inMessage:primaryMessage
                                                         error:nil];
            NSString *primaryID = NTYTExactlyOneString(primaryStrings, YES);
            if (primaryID) {
                NSString *corroboratingID = nil;
                NSArray<NSData *> *corroboratingMessages =
                    [NTYTProtobufReader messagesAtPath:@[@8, @382320942]
                                                inData:primaryMessage
                                                 error:nil];
                if (corroboratingMessages.count == 1) {
                    NSArray<NSString *> *corroboratingStrings =
                        [NTYTProtobufReader UTF8StringsForDirectField:1
                                                            inMessage:corroboratingMessages.firstObject
                                                                 error:nil];
                    corroboratingID = NTYTExactlyOneString(corroboratingStrings, YES);
                }

                if (!corroboratingID || [corroboratingID isEqualToString:primaryID]) {
                    resolvedVideoID = primaryID;
                }
            }
        }

        NSString *title = nil;
        NSString *channelName = nil;
        if (resolvedVideoID) {
            NSMutableArray<NSData *> *matchingCandidates = [NSMutableArray array];
            for (NSArray<NSNumber *> *richPath in NTYTRichMetadataPaths()) {
                NSArray<NSData *> *richCandidates =
                    [NTYTProtobufReader messagesAtPath:richPath
                                                inData:data
                                                 error:nil];
                for (NSData *candidate in richCandidates ?: @[]) {
                    NSArray<NSString *> *candidateIDs =
                        [NTYTProtobufReader UTF8StringsForDirectField:1
                                                            inMessage:candidate
                                                                 error:nil];
                    NSString *candidateID = NTYTExactlyOneString(candidateIDs, YES);
                    if (candidateID && [candidateID isEqualToString:resolvedVideoID]) {
                        [matchingCandidates addObject:candidate];
                    }
                }
            }
            if (matchingCandidates.count == 1) {
                NSData *candidate = matchingCandidates.firstObject;
                title = NTYTExactlyOneString(
                    [NTYTProtobufReader UTF8StringsForDirectField:36
                                                        inMessage:candidate
                                                             error:nil],
                    NO);
                channelName = NTYTExactlyOneString(
                    [NTYTProtobufReader UTF8StringsForDirectField:37
                                                        inMessage:candidate
                                                             error:nil],
                    NO);
            }
        }

        NSString *channelID = nil;
        NSString *handle = nil;
        NSArray<NSData *> *channelCandidates =
            [NTYTProtobufReader messagesAtPath:NTYTChannelMetadataPath()
                                        inData:data
                                         error:nil];
        if (channelCandidates.count == 1) {
            NSData *candidate = channelCandidates.firstObject;
            channelID = NTYTExactlyOneString(
                [NTYTProtobufReader UTF8StringsForDirectField:2
                                                    inMessage:candidate
                                                         error:nil],
                YES);
            handle = NTYTExactlyOneString(
                [NTYTProtobufReader UTF8StringsForDirectField:4
                                                    inMessage:candidate
                                                         error:nil],
                YES);
        }

        NTYTContentMetadata *metadata =
            [[NTYTContentMetadata alloc] initWithContentType:NTYTContentTypeVideo
                                                    videoID:resolvedVideoID
                                                      title:title
                                                  channelID:channelID
                                                channelName:channelName
                                                     handle:handle];
        return [NTYTMetadataExtractionResult successWithMetadata:metadata];
    } @catch (NSException *exception) {
        return [NTYTMetadataExtractionResult failureWithError:
            NTYTExtractionError(4, exception.reason ?: @"Metadata extraction failed internally.")];
    }
}

@end
