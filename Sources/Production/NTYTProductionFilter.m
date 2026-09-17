#import "NTYTProductionFilter.h"

#import <YouTubeHeader/YTIElementRenderer.h>
#import <YouTubeHeader/YTISectionListRenderer.h>

#import "Core/NTYTContentMetadata.h"
#import "Core/NTYTRuntimeModel.h"
#import "Core/NTYTSnapshotHolder.h"
#import "Evaluation/NTYTEvaluator.h"
#import "Extraction/NTYTMetadataExtractor.h"
#import "Debug/LogHelper.h"

@interface NSObject (NTYTElementRendererAccess)
- (nullable id)elementRenderer;
@end

@interface YTIElementRendererCompatibilityOptions (NTYTProduction)
- (BOOL)useVideoCellControllerOnIos;
@end

static const BOOL NTYTEmptySectionCollectionSafetyVerified = NO;

@implementation NTYTProductionFilter

+ (YTIElementRenderer *)supportedElementRendererFromSection:(YTIItemSectionRenderer *)section {
    id contentsValue = [section contentsArray];
    if (![contentsValue isKindOfClass:[NSArray class]]) {
        return nil;
    }
    NSArray *contents = (NSArray *)contentsValue;
    if (contents.count != 1) {
        return nil;
    }

    id wrapper = contents.firstObject;
    if (![wrapper respondsToSelector:@selector(elementRenderer)]) {
        return nil;
    }
    id element = [wrapper elementRenderer];
    Class elementClass = NSClassFromString(@"YTIElementRenderer");
    if (!elementClass || ![element isKindOfClass:elementClass]) {
        return nil;
    }
    return (YTIElementRenderer *)element;
}

+ (BOOL)isQualifiedVideoElement:(YTIElementRenderer *)element {
    if ([element respondsToSelector:@selector(hasCompatibilityOptions)] &&
        ![element hasCompatibilityOptions]) {
        return NO;
    }
    id options = [element compatibilityOptions];
    if (!options || ![options respondsToSelector:@selector(useVideoCellControllerOnIos)]) {
        return NO;
    }
    return [(YTIElementRendererCompatibilityOptions *)options useVideoCellControllerOnIos];
}

+ (NSArray *)filteredSectionCollectionFromOriginal:(NSArray *)originalCollection {
    if (![originalCollection isKindOfClass:[NSArray class]] || originalCollection.count == 0) {
        return originalCollection;
    }

    @try {
        NTYTRuntimeSettingsSnapshot *snapshot =
            [[NTYTSnapshotHolder sharedHolder] currentSnapshot];
        if (!snapshot) {
            return originalCollection;
        }

        Class sectionClass = NSClassFromString(@"YTIItemSectionRenderer");
        if (!sectionClass) {
            return originalCollection;
        }

        NSMutableArray *filtered = [NSMutableArray arrayWithCapacity:originalCollection.count];
        BOOL removedAnySection = NO;

        for (id candidate in originalCollection) {
            BOOL removeSection = NO;
            if ([candidate isKindOfClass:sectionClass]) {
                @try {
                    YTIElementRenderer *element =
                        [self supportedElementRendererFromSection:(YTIItemSectionRenderer *)candidate];
                    if (element && [self isQualifiedVideoElement:element]) {
                        NTYTMetadataExtractionResult *extraction =
                            [NTYTMetadataExtractor extractFromElementRenderer:element];

                        if (extraction.isSuccess && extraction.metadata) {
                            NTYTContentMetadata *metadata = extraction.metadata;

                            NTYTDecision decision =
                                [NTYTEvaluator decisionForMetadata:metadata
                                                          snapshot:snapshot];

                            NTYTLog(@"[Filter] videoID=%@ title=%@ channelID=%@ channelName=%@ handle=%@ decision=%ld",
                                    metadata.videoID ?: @"<unavailable>",
                                    metadata.title ?: @"<unavailable>",
                                    metadata.channelID ?: @"<unavailable>",
                                    metadata.channelName ?: @"<unavailable>",
                                    metadata.handle ?: @"<unavailable>",
                                    (long)decision);

                            removeSection = decision == NTYTDecisionBlock;
                        } else {
                            NTYTLog(@"[Filter] extraction failure: %@",
                                    extraction.error.localizedDescription ?: @"<unknown>");
                        }
                    }
                } @catch (NSException *sectionException) {
                    NTYTLog(@"[Filter] section fail-open: %@",
                            sectionException.reason ?: @"<unknown>");
                    removeSection = NO;
                }
            }

            if (removeSection) {
                removedAnySection = YES;
            } else {
                [filtered addObject:candidate];
            }
        }

        if (!removedAnySection) {
            return originalCollection;
        }

        if (filtered.count == 0 && !NTYTEmptySectionCollectionSafetyVerified) {
            NTYTLog(@"[Filter] fail-open: filtered result would be empty");
            return originalCollection;
        }

        return filtered;
    } @catch (NSException *containerException) {
        NTYTLog(@"[Filter] container rollback: %@",
                containerException.reason ?: @"<unknown>");
        return originalCollection;
    }
}

@end
