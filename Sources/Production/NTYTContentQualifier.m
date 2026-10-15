#import "NTYTContentQualifier.h"

#import <YouTubeHeader/YTIElementRenderer.h>

#import "Extraction/NTYTElementQualificationPrivate.h"
#import "Extraction/NTYTProtobufReader.h"

@interface YTIElementRenderer (NTYTQualificationDataAccess)
- (NSData * _Nullable)elementData;
@end

@interface YTIElementRendererCompatibilityOptions (NTYTQualification)
- (BOOL)useVideoCellControllerOnIos;
- (BOOL)useBackstageCellControllerOnIos;
@end

@interface NSObject (NTYTShortsShelfWrapperAccess)
- (nullable id)elementRenderer;
@end

@implementation NTYTElementQualification

- (instancetype)initWithSemanticResult:(NTYTSemanticQualificationResult *)semanticResult
                  validatedElementData:(NSData *)validatedElementData
                      videoCellVariant:(NTYTVideoCellVariant)videoCellVariant {
    self = [super init];
    if (self) {
        _semanticResult = semanticResult;
        _validatedElementData = [validatedElementData copy];
        _videoCellVariant = videoCellVariant;
    }
    return self;
}

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
        [NTYTProtobufReader varintValuesForField:fieldNumber inData:message error:nil];
    return values.count == 1 && values.firstObject.unsignedLongLongValue == expectedValue;
}

static NTYTPlaylistSubtype NTYTQualifiedPlaylistSubtype(NSData *data) {
    NSArray<NSData *> *messages =
        [NTYTProtobufReader messagesAtPath:NTYTPlaylistSubtypePath() inData:data error:nil];
    if (messages.count != 1) return NTYTPlaylistSubtypeUnresolved;
    NSData *message = messages.firstObject;
    BOOL normal = NTYTExactlyOneVarintEquals(message, 7, 1) &&
                  NTYTExactlyOneVarintEquals(message, 8, 0) &&
                  NTYTExactlyOneVarintEquals(message, 36, 4);
    BOOL mix = NTYTExactlyOneVarintEquals(message, 7, 0) &&
               NTYTExactlyOneVarintEquals(message, 8, 1) &&
               NTYTExactlyOneVarintEquals(message, 36, 8);
    if (normal == mix) return NTYTPlaylistSubtypeUnresolved;
    return normal ? NTYTPlaylistSubtypeNormal : NTYTPlaylistSubtypeMix;
}

static BOOL NTYTPlaylistFamilyPositive(NSData *data) {
    if (!data) return NO;
    NSArray<NSData *> *messages =
        [NTYTProtobufReader messagesAtPath:NTYTPlaylistFamilyParentPath() inData:data error:nil];
    return messages.count == 1 && NTYTExactlyOneVarintEquals(messages.firstObject, 38, 1);
}

// Complete traversal and leaf validation precede a presentation positive.
// No sample-derived occurrence count is a qualification gate.
static NSArray<NSData *> *NTYTSafeMessages(NSData *data, NSArray<NSNumber *> *path) {
    if (!data) return nil;
    NSArray<NSData *> *messages = [NTYTProtobufReader messagesAtPath:path inData:data error:nil];
    if (!messages) return nil;
    for (NSData *message in messages) {
        if (![NTYTProtobufReader validateMessageData:message error:nil]) return nil;
    }
    return messages;
}

static NTYTPresentationQualification NTYTPresentationForMessages(NSArray<NSData *> *messages) {
    if (!messages) return NTYTPresentationQualificationUnavailable;
    return messages.count > 0 ? NTYTPresentationQualificationConfirmed
                              : NTYTPresentationQualificationNotConfirmed;
}

static NTYTPresentationQualification NTYTAdSupportedFreeMovieQualification(NSData *data) {
    NSArray<NSData *> *messages = NTYTSafeMessages(
        data,
        @[@1, @168777401, @5, @232954548, @18, @1, @21, @8178, @3,
          @514549827, @1, @2, @1147]);
    if (!messages) return NTYTPresentationQualificationUnavailable;
    BOOL foundPositive = NO;
    for (NSData *message in messages) {
        NSArray<NSNumber *> *values =
            [NTYTProtobufReader varintValuesForField:3 inData:message error:nil];
        if (!values) return NTYTPresentationQualificationUnavailable;
        if ([values containsObject:@3]) foundPositive = YES;
    }
    return foundPositive ? NTYTPresentationQualificationConfirmed
                         : NTYTPresentationQualificationNotConfirmed;
}

static NSArray<NSData *> *NTYTStandaloneHorizontalPayloads(NSData *data) {
    return NTYTSafeMessages(data, @[@1, @168777401, @5, @312131490, @20]);
}

static NTYTHorizontalShelfException NTYTHorizontalException(NSArray<NSData *> *payloads) {
    BOOL history = NO;
    BOOL playlist = NO;
    for (NSData *payload in payloads) {
        NSArray<NSData *> *parents = NTYTSafeMessages(payload, @[@1]);
        if (!parents) return NTYTHorizontalShelfExceptionUnavailable;
        for (NSData *parent in parents) {
            NSArray<NSData *> *markers = NTYTSafeMessages(parent, @[@6]);
            if (!markers) return NTYTHorizontalShelfExceptionUnavailable;
            NSNumber *field25Present = [NTYTProtobufReader hasDirectField:25 inData:parent error:nil];
            if (!field25Present) return NTYTHorizontalShelfExceptionUnavailable;
            for (NSData *marker in markers) {
                NSArray<NSNumber *> *values =
                    [NTYTProtobufReader varintValuesForField:2 inData:marker error:nil];
                if (!values) return NTYTHorizontalShelfExceptionUnavailable;
                if ([values containsObject:@183117] && !field25Present.boolValue) history = YES;
                if ([values containsObject:@183121]) playlist = YES;
            }
        }
    }
    if (history && playlist) return NTYTHorizontalShelfExceptionUnavailable;
    if (history) return NTYTHorizontalShelfExceptionHistory;
    if (playlist) return NTYTHorizontalShelfExceptionPlaylist;
    return NTYTHorizontalShelfExceptionOther;
}

static void NTYTQualifyHorizontal(NSData *data, BOOL standaloneOnly,
                                  NTYTPresentationQualification *presentation,
                                  NTYTHorizontalShelfException *exception) {
    *exception = NTYTHorizontalShelfExceptionUnavailable;
    NSArray<NSData *> *standalone = NTYTStandaloneHorizontalPayloads(data);
    *presentation = NTYTPresentationForMessages(standalone);
    if (standaloneOnly) {
        if (*presentation == NTYTPresentationQualificationConfirmed) {
            *exception = NTYTHorizontalException(standalone);
        }
        return;
    }

    NSArray<NSData *> *chips = NTYTSafeMessages(data, @[@1, @168777401, @5, @413471385, @1, @504871679]);
    if (!standalone || !chips) {
        *presentation = NTYTPresentationQualificationUnavailable;
        return;
    }
    NSMutableArray<NSData *> *payloads = [standalone mutableCopy];
    if (chips.count > 0) {
        NSMutableArray<NSData *> *linkedTargets = [NSMutableArray array];
        for (NSData *parent in chips) {
            NSArray<NSData *> *linked = NTYTSafeMessages(parent, @[@101, @1, @1, @1, @153515154,
                @172660663, @1, @168777401, @5, @312131490, @20]);
            if (!linked) {
                *presentation = NTYTPresentationQualificationUnavailable;
                return;
            }
            [linkedTargets addObjectsFromArray:linked];
        }
        // Exactly one linked target across the complete fixed-path traversal; no deduplication.
        if (linkedTargets.count != 1) {
            *presentation = NTYTPresentationQualificationUnavailable;
            return;
        }
        [payloads addObject:linkedTargets.firstObject];
    }
    *presentation = NTYTPresentationForMessages(payloads);
    if (*presentation == NTYTPresentationQualificationConfirmed) {
        *exception = NTYTHorizontalException(payloads);
    }
}

static NTYTShortsClassification NTYTVideoShortsClassification(NSData *data) {
    if (!data) return NTYTShortsClassificationUnavailable;
    @try {
        NSArray<NSData *> *messages = [NTYTProtobufReader
            messagesAtPath:NTYTPlaylistSubtypePath() inData:data error:nil];
        if (!messages) return NTYTShortsClassificationUnavailable;
        BOOL foundShortsMarker = NO;
        for (NSData *message in messages) {
            NSArray<NSNumber *> *field25Values =
                [NTYTProtobufReader varintValuesForField:25 inData:message error:nil];
            NSArray<NSNumber *> *field26Values =
                [NTYTProtobufReader varintValuesForField:26 inData:message error:nil];
            if (!field25Values || !field26Values) return NTYTShortsClassificationUnavailable;
            // Existing classifier: both markers in one message; repeated values allowed.
            if ([field25Values containsObject:@3] && [field26Values containsObject:@452984831]) {
                foundShortsMarker = YES;
            }
        }
        return foundShortsMarker ? NTYTShortsClassificationShorts : NTYTShortsClassificationNonShorts;
    } @catch (__unused NSException *exception) {
        return NTYTShortsClassificationUnavailable;
    }
}

static NTYTSemanticQualificationResult *NTYTShortsShelfQualification(NTYTPresentationQualification state) {
    return [[NTYTSemanticQualificationResult alloc]
        initWithContentFamily:NTYTContentFamilyUnresolved playlistSubtype:NTYTPlaylistSubtypeUnresolved
         shortsClassification:NTYTShortsClassificationUnavailable
              horizontalShelf:NTYTPresentationQualificationUnavailable
     horizontalShelfException:NTYTHorizontalShelfExceptionUnavailable
                  shortsShelf:state fromYouTubeCell:NTYTPresentationQualificationUnavailable
             adSupportedFreeMovie:NTYTPresentationQualificationUnavailable
                      cellDivider:NTYTPresentationQualificationUnavailable];
}

@interface NTYTContentQualifier ()
+ (NTYTElementQualification *)qualificationForElementRenderer:(YTIElementRenderer *)elementRenderer
                                   standaloneHorizontalOnly:(BOOL)standaloneOnly;
@end

@implementation NTYTContentQualifier

+ (NTYTElementQualification *)qualificationForElementRenderer:(YTIElementRenderer *)elementRenderer {
    return [self qualificationForElementRenderer:elementRenderer standaloneHorizontalOnly:NO];
}

+ (NTYTElementQualification *)qualificationForStandaloneHorizontalElementRenderer:(YTIElementRenderer *)elementRenderer {
    return [self qualificationForElementRenderer:elementRenderer standaloneHorizontalOnly:YES];
}

+ (NTYTElementQualification *)qualificationForElementRenderer:(YTIElementRenderer *)elementRenderer
                                   standaloneHorizontalOnly:(BOOL)standaloneOnly {
    NSData *data = nil;
    if ([elementRenderer respondsToSelector:@selector(elementData)]) {
        id value = [elementRenderer elementData];
        if ([value isKindOfClass:[NSData class]]) {
            NSData *captured = [value copy];
            if ([NTYTProtobufReader validateMessageData:captured error:nil]) data = captured;
        }
    }

    NTYTPresentationQualification horizontal;
    NTYTHorizontalShelfException horizontalException;
    NTYTQualifyHorizontal(data, standaloneOnly, &horizontal, &horizontalException);
    NTYTContentFamily family = NTYTContentFamilyUnresolved;
    NTYTPlaylistSubtype subtype = NTYTPlaylistSubtypeUnresolved;
    NTYTShortsClassification shorts = NTYTShortsClassificationUnavailable;
    NTYTPresentationQualification fromYouTube = NTYTPresentationQualificationUnavailable;
    NTYTPresentationQualification shortsShelf = NTYTPresentationQualificationUnavailable;
    NTYTPresentationQualification freeMovie = NTYTPresentationQualificationUnavailable;
    NTYTPresentationQualification cellDivider = NTYTPresentationQualificationUnavailable;
    NTYTVideoCellVariant variant = NTYTVideoCellVariantStandard;

    if (!standaloneOnly) {
        BOOL standardVideo = NO;
        BOOL post = NO;
        if (![elementRenderer respondsToSelector:@selector(hasCompatibilityOptions)] ||
            [elementRenderer hasCompatibilityOptions]) {
            id options = [elementRenderer compatibilityOptions];
            if ([options respondsToSelector:@selector(useVideoCellControllerOnIos)]) {
                standardVideo = [(YTIElementRendererCompatibilityOptions *)options useVideoCellControllerOnIos];
            }
            if ([options respondsToSelector:@selector(useBackstageCellControllerOnIos)]) {
                post = [(YTIElementRendererCompatibilityOptions *)options useBackstageCellControllerOnIos];
            }
        }
        fromYouTube = NTYTPresentationForMessages(NTYTSafeMessages(data, @[@1, @168777401, @5, @400581496]));
        BOOL fromYouTubeVideo = fromYouTube == NTYTPresentationQualificationConfirmed;
        freeMovie = NTYTAdSupportedFreeMovieQualification(data);
        cellDivider = NTYTPresentationForMessages(
            NTYTSafeMessages(data, @[@1, @168777401, @5, @347043917]));
        BOOL video = standardVideo || fromYouTubeVideo ||
                     freeMovie == NTYTPresentationQualificationConfirmed;
        BOOL playlist = NTYTPlaylistFamilyPositive(data);
        NSUInteger positiveFamilies = (video ? 1 : 0) + (post ? 1 : 0) + (playlist ? 1 : 0);
        if (positiveFamilies == 1) {
            if (video) {
                family = NTYTContentFamilyVideo;
                if (fromYouTubeVideo) {
                    variant = NTYTVideoCellVariantFromYouTube;
                    // No confirmed classifier exists for this variant.
                    shorts = NTYTShortsClassificationUnavailable;
                } else {
                    shorts = NTYTVideoShortsClassification(data);
                }
            } else if (post) {
                family = NTYTContentFamilyPost;
                shorts = NTYTShortsClassificationNonShorts;
            } else {
                family = NTYTContentFamilyPlaylist;
                subtype = NTYTQualifiedPlaylistSubtype(data);
                shorts = NTYTShortsClassificationNonShorts;
            }
        }
        shortsShelf = NTYTPresentationForMessages(NTYTSafeMessages(data, @[@1, @168777401, @5, @315733268]));
    }

    NTYTSemanticQualificationResult *semantic = [[NTYTSemanticQualificationResult alloc]
        initWithContentFamily:family playlistSubtype:subtype shortsClassification:shorts
              horizontalShelf:horizontal horizontalShelfException:horizontalException
                  shortsShelf:shortsShelf fromYouTubeCell:fromYouTube
             adSupportedFreeMovie:freeMovie cellDivider:cellDivider];
    return [[NTYTElementQualification alloc] initWithSemanticResult:semantic
                                             validatedElementData:data videoCellVariant:variant];
}

+ (NTYTSemanticQualificationResult *)qualificationForHorizontalListItems:(NSArray *)items {
    if (![items isKindOfClass:[NSArray class]]) {
        return NTYTShortsShelfQualification(NTYTPresentationQualificationUnavailable);
    }
    if (items.count == 0) {
        return NTYTShortsShelfQualification(NTYTPresentationQualificationNotConfirmed);
    }
    Class elementClass = NSClassFromString(@"YTIElementRenderer");
    BOOL allCellsConfirmed = YES;
    for (id wrapper in items) {
        if (![wrapper respondsToSelector:@selector(elementRenderer)]) {
            return NTYTShortsShelfQualification(NTYTPresentationQualificationUnavailable);
        }
        id element = [wrapper elementRenderer];
        if (!elementClass || ![element isKindOfClass:elementClass] ||
            ![element respondsToSelector:@selector(elementData)]) {
            return NTYTShortsShelfQualification(NTYTPresentationQualificationUnavailable);
        }
        id value = [element elementData];
        if (![value isKindOfClass:[NSData class]] ||
            ![NTYTProtobufReader validateMessageData:value error:nil]) {
            return NTYTShortsShelfQualification(NTYTPresentationQualificationUnavailable);
        }
        NSArray *cells = NTYTSafeMessages(value, @[@1, @168777401, @5, @519005951]);
        if (!cells) return NTYTShortsShelfQualification(NTYTPresentationQualificationUnavailable);
        if (cells.count == 0) allCellsConfirmed = NO;
    }
    return NTYTShortsShelfQualification(allCellsConfirmed ? NTYTPresentationQualificationConfirmed
                                                        : NTYTPresentationQualificationNotConfirmed);
}

@end
