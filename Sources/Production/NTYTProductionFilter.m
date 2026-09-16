#import "NTYTProductionFilter.h"

#import <YouTubeHeader/YTIElementRenderer.h>
#import <YouTubeHeader/YTISectionListRenderer.h>

#import "Core/NTYTRuntimeModel.h"
#import "Core/NTYTSnapshotHolder.h"
#import "Evaluation/NTYTEvaluator.h"
#import "Extraction/NTYTMetadataExtractor.h"

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
                            NTYTDecision decision =
                                [NTYTEvaluator decisionForMetadata:extraction.metadata
                                                          snapshot:snapshot];
                            removeSection = decision == NTYTDecisionBlock;
                        }
                    }
                } @catch (__unused NSException *sectionException) {
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
            return originalCollection;
        }

        return [filtered copy];
    } @catch (__unused NSException *containerException) {
        return originalCollection;
    }
}

@end
