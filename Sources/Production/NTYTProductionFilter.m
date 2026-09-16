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

@interface YTIItemSectionRenderer (NTYTProductionContentsMutation)
- (nullable id)copyWithZone:(nullable NSZone *)zone;
- (void)setContentsArray:(NSMutableArray *)contentsArray;
@end

@interface YTIElementRendererCompatibilityOptions (NTYTProduction)
- (BOOL)useVideoCellControllerOnIos;
@end

static const BOOL NTYTEmptySectionCollectionSafetyVerified = NO;

@implementation NTYTProductionFilter

+ (nullable YTIElementRenderer *)elementRendererFromContentEntry:(id)entry {
    if (![entry respondsToSelector:@selector(elementRenderer)]) {
        NTYTLog(@"[FilterDiag] keep child: wrapper=%@ has no elementRenderer",
                entry ? NSStringFromClass([entry class]) : @"<nil>");
        return nil;
    }

    id element = [entry elementRenderer];
    Class elementClass = NSClassFromString(@"YTIElementRenderer");
    if (!elementClass || ![element isKindOfClass:elementClass]) {
        NTYTLog(@"[FilterDiag] keep child: element=%@ expected=YTIElementRenderer",
                element ? NSStringFromClass([element class]) : @"<nil>");
        return nil;
    }

    return (YTIElementRenderer *)element;
}

+ (BOOL)isQualifiedVideoElement:(YTIElementRenderer *)element {
    if ([element respondsToSelector:@selector(hasCompatibilityOptions)] &&
        ![element hasCompatibilityOptions]) {
        NTYTLog(@"[FilterDiag] keep child: hasCompatibilityOptions=NO");
        return NO;
    }

    id options = [element compatibilityOptions];
    if (!options || ![options respondsToSelector:@selector(useVideoCellControllerOnIos)]) {
        NTYTLog(@"[FilterDiag] keep child: compatibilityOptions=%@ video selector unavailable",
                options ? NSStringFromClass([options class]) : @"<nil>");
        return NO;
    }

    BOOL qualified =
        [(YTIElementRendererCompatibilityOptions *)options useVideoCellControllerOnIos];

    if (!qualified) {
        NTYTLog(@"[FilterDiag] keep child: useVideoCellControllerOnIos=NO");
    }

    return qualified;
}

+ (BOOL)shouldRemoveContentEntry:(id)entry
                        snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot
                      childIndex:(NSUInteger)childIndex {
    @try {
        YTIElementRenderer *element = [self elementRendererFromContentEntry:entry];
        if (!element || ![self isQualifiedVideoElement:element]) {
            return NO;
        }

        NTYTMetadataExtractionResult *extraction =
            [NTYTMetadataExtractor extractFromElementRenderer:element];

        if (!extraction.isSuccess || !extraction.metadata) {
            NTYTLog(@"[Filter] child=%lu extraction failure: %@",
                    (unsigned long)childIndex,
                    extraction.error.localizedDescription ?: @"<unknown>");
            return NO;
        }

        NTYTContentMetadata *metadata = extraction.metadata;
        NTYTDecision decision =
            [NTYTEvaluator decisionForMetadata:metadata snapshot:snapshot];

        NTYTLog(@"[Filter] child=%lu videoID=%@ title=%@ channelID=%@ channelName=%@ handle=%@ decision=%ld",
                (unsigned long)childIndex,
                metadata.videoID ?: @"<unavailable>",
                metadata.title ?: @"<unavailable>",
                metadata.channelID ?: @"<unavailable>",
                metadata.channelName ?: @"<unavailable>",
                metadata.handle ?: @"<unavailable>",
                (long)decision);

        return decision == NTYTDecisionBlock;
    } @catch (NSException *childException) {
        NTYTLog(@"[Filter] child=%lu fail-open: %@",
                (unsigned long)childIndex,
                childException.reason ?: @"<unknown>");
        return NO;
    }
}

+ (BOOL)contentsArray:(NSArray *)actual
matchesRetainedChildren:(NSArray *)expected {
    if (actual.count != expected.count) {
        return NO;
    }

    for (NSUInteger index = 0; index < expected.count; index++) {
        if ([actual objectAtIndex:index] != [expected objectAtIndex:index]) {
            return NO;
        }
    }

    return YES;
}

+ (nullable YTIItemSectionRenderer *)copiedSectionFromSection:(YTIItemSectionRenderer *)section
                                             retainedChildren:(NSMutableArray *)retainedChildren {
    if (![section respondsToSelector:@selector(copyWithZone:)] ||
        ![section respondsToSelector:@selector(setContentsArray:)]) {
        NTYTLog(@"[Filter] section copy fail-open: copy/setter capability unavailable");
        return nil;
    }

    id copiedValue = [section copyWithZone:nil];
    Class sectionClass = NSClassFromString(@"YTIItemSectionRenderer");
    if (!copiedValue || copiedValue == section ||
        !sectionClass || ![copiedValue isKindOfClass:sectionClass]) {
        NTYTLog(@"[Filter] section copy fail-open: invalid copy class=%@ sameObject=%@",
                copiedValue ? NSStringFromClass([copiedValue class]) : @"<nil>",
                copiedValue == section ? @"YES" : @"NO");
        return nil;
    }

    YTIItemSectionRenderer *copiedSection =
        (YTIItemSectionRenderer *)copiedValue;

    if (![copiedSection respondsToSelector:@selector(setContentsArray:)]) {
        NTYTLog(@"[Filter] section copy fail-open: copied section setter unavailable");
        return nil;
    }

    [copiedSection setContentsArray:retainedChildren];

    id committedContentsValue = [copiedSection contentsArray];
    if (![committedContentsValue isKindOfClass:[NSArray class]] ||
        ![self contentsArray:(NSArray *)committedContentsValue
      matchesRetainedChildren:retainedChildren]) {
        NTYTLog(@"[Filter] section copy fail-open: replacement postcondition failed");
        return nil;
    }

    return copiedSection;
}

+ (nullable YTIItemSectionRenderer *)filteredSectionFromSection:(YTIItemSectionRenderer *)section
                                                       snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot {
    id contentsValue = [section contentsArray];
    if (![contentsValue isKindOfClass:[NSArray class]]) {
        NTYTLog(@"[FilterDiag] keep section: contentsArray class=%@",
                contentsValue ? NSStringFromClass([contentsValue class]) : @"<nil>");
        return section;
    }

    NSArray *contents = (NSArray *)contentsValue;
    if (contents.count == 0) {
        NTYTLog(@"[FilterDiag] keep section: contentsArray.count=0");
        return section;
    }

    NSMutableArray *retainedChildren =
        [NSMutableArray arrayWithCapacity:contents.count];
    BOOL removedAnyChild = NO;
    NSUInteger childIndex = 0;

    for (id entry in contents) {
        BOOL removeChild =
            [self shouldRemoveContentEntry:entry
                                  snapshot:snapshot
                                childIndex:childIndex];

        if (removeChild) {
            removedAnyChild = YES;
        } else {
            [retainedChildren addObject:entry];
        }

        childIndex++;
    }

    if (!removedAnyChild) {
        return section;
    }

    if (retainedChildren.count == 0) {
        NTYTLog(@"[Filter] remove section: all %lu children blocked",
                (unsigned long)contents.count);
        return nil;
    }

    YTIItemSectionRenderer *copiedSection =
        [self copiedSectionFromSection:section
                      retainedChildren:retainedChildren];

    if (!copiedSection) {
        return section;
    }

    NTYTLog(@"[Filter] partial section commit: inputChildren=%lu retainedChildren=%lu",
            (unsigned long)contents.count,
            (unsigned long)retainedChildren.count);

    return copiedSection;
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

        NSMutableArray *filtered =
            [NSMutableArray arrayWithCapacity:originalCollection.count];
        BOOL changedAnySection = NO;

        for (id candidate in originalCollection) {
            id resultCandidate = candidate;
            BOOL removeCandidate = NO;

            if ([candidate isKindOfClass:sectionClass]) {
                @try {
                    YTIItemSectionRenderer *sectionResult =
                        [self filteredSectionFromSection:(YTIItemSectionRenderer *)candidate
                                                 snapshot:snapshot];

                    if (!sectionResult) {
                        removeCandidate = YES;
                        changedAnySection = YES;
                    } else {
                        resultCandidate = sectionResult;
                        if (sectionResult != candidate) {
                            changedAnySection = YES;
                        }
                    }
                } @catch (NSException *sectionException) {
                    NTYTLog(@"[Filter] section fail-open: %@",
                            sectionException.reason ?: @"<unknown>");
                    resultCandidate = candidate;
                    removeCandidate = NO;
                }
            }

            if (!removeCandidate) {
                [filtered addObject:resultCandidate];
            }
        }

        if (!changedAnySection) {
            return originalCollection;
        }

        if (filtered.count == 0 && !NTYTEmptySectionCollectionSafetyVerified) {
            NTYTLog(@"[Filter] fail-open: filtered outer result would be empty");
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
