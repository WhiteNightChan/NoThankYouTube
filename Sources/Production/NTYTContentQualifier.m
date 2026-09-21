#import "NTYTContentQualifier.h"

#import <YouTubeHeader/YTIElementRenderer.h>

#import "Extraction/NTYTProtobufReader.h"

@interface YTIElementRenderer (NTYTQualificationDataAccess)
- (NSData * _Nullable)elementData;
@end

@interface YTIElementRendererCompatibilityOptions (NTYTQualification)
- (BOOL)useVideoCellControllerOnIos;
- (BOOL)useBackstageCellControllerOnIos;
@end

static NSArray<NSNumber *> *NTYTPlaylistFamilyParentPath(void) {
    return @[@1, @168777401, @5, @232954548, @18];
}

static NSArray<NSNumber *> *NTYTPlaylistSubtypePath(void) {
    return @[@1, @168777401, @5, @232954548, @18, @1, @1];
}

static BOOL NTYTExactlyOneVarintEquals(NSData *message,
                                       uint32_t fieldNumber,
                                       uint64_t expectedValue) {
    NSArray<NSNumber *> *values =
        [NTYTProtobufReader varintValuesForField:fieldNumber
                                          inData:message
                                           error:nil];
    return values.count == 1 && values.firstObject.unsignedLongLongValue == expectedValue;
}

static NTYTContentType NTYTQualifiedPlaylistSubtype(NSData *data) {
    NSArray<NSData *> *subtypeMessages =
        [NTYTProtobufReader messagesAtPath:NTYTPlaylistSubtypePath()
                                    inData:data
                                     error:nil];
    if (subtypeMessages.count != 1) {
        return NTYTContentTypeUnresolved;
    }

    NSData *message = subtypeMessages.firstObject;
    BOOL normal = NTYTExactlyOneVarintEquals(message, 7, 1) &&
                  NTYTExactlyOneVarintEquals(message, 8, 0) &&
                  NTYTExactlyOneVarintEquals(message, 36, 4);
    BOOL mix = NTYTExactlyOneVarintEquals(message, 7, 0) &&
               NTYTExactlyOneVarintEquals(message, 8, 1) &&
               NTYTExactlyOneVarintEquals(message, 36, 8);

    if (normal == mix) {
        return NTYTContentTypeUnresolved;
    }
    return normal ? NTYTContentTypePlaylistNormal : NTYTContentTypePlaylistMix;
}

static NTYTContentType NTYTPlaylistQualification(NSData *data,
                                                  BOOL *familyPositive) {
    if (familyPositive) {
        *familyPositive = NO;
    }
    if (![data isKindOfClass:[NSData class]] ||
        ![NTYTProtobufReader validateMessageData:data error:nil]) {
        return NTYTContentTypeUnresolved;
    }

    NSArray<NSData *> *parentMessages =
        [NTYTProtobufReader messagesAtPath:NTYTPlaylistFamilyParentPath()
                                    inData:data
                                     error:nil];
    if (parentMessages.count != 1 ||
        !NTYTExactlyOneVarintEquals(parentMessages.firstObject, 38, 1)) {
        return NTYTContentTypeUnresolved;
    }

    if (familyPositive) {
        *familyPositive = YES;
    }
    return NTYTQualifiedPlaylistSubtype(data);
}

@implementation NTYTContentQualifier

+ (NTYTContentType)qualifiedContentTypeForElementRenderer:(YTIElementRenderer *)elementRenderer {
    if (!elementRenderer) {
        return NTYTContentTypeUnresolved;
    }

    @try {
        BOOL videoPositive = NO;
        BOOL postPositive = NO;
        if (![elementRenderer respondsToSelector:@selector(hasCompatibilityOptions)] ||
            [elementRenderer hasCompatibilityOptions]) {
            id options = [elementRenderer compatibilityOptions];
            if ([options respondsToSelector:@selector(useVideoCellControllerOnIos)]) {
                videoPositive =
                    [(YTIElementRendererCompatibilityOptions *)options useVideoCellControllerOnIos];
            }
            if ([options respondsToSelector:@selector(useBackstageCellControllerOnIos)]) {
                postPositive =
                    [(YTIElementRendererCompatibilityOptions *)options useBackstageCellControllerOnIos];
            }
        }

        NTYTContentType playlistSubtype = NTYTContentTypeUnresolved;
        BOOL playlistPositive = NO;
        if ([elementRenderer respondsToSelector:@selector(elementData)]) {
            id value = [elementRenderer elementData];
            if ([value isKindOfClass:[NSData class]]) {
                playlistSubtype = NTYTPlaylistQualification((NSData *)value,
                                                             &playlistPositive);
            }
        }

        NSUInteger positiveFamilyCount = (videoPositive ? 1 : 0) +
                                         (postPositive ? 1 : 0) +
                                         (playlistPositive ? 1 : 0);
        if (positiveFamilyCount != 1) {
            return NTYTContentTypeUnresolved;
        }
        if (videoPositive) {
            return NTYTContentTypeVideo;
        }
        if (postPositive) {
            return NTYTContentTypePost;
        }
        if (playlistSubtype == NTYTContentTypeUnresolved) {
            return NTYTContentTypeUnresolved;
        }
        return playlistSubtype;
    } @catch (__unused NSException *exception) {
        return NTYTContentTypeUnresolved;
    }
}

@end
