#import "NTYTSectionCollectionAdapter.h"

#import <YouTubeHeader/YTISectionListRenderer.h>
#import <YouTubeHeader/YTIShelfRenderer.h>

#import "Core/NTYTRuntimeModel.h"
#import "Core/NTYTSnapshotHolder.h"
#import "NTYTProductionFilter.h"
#import "Debug/LogHelper.h"

@implementation NTYTSectionCollectionAdapter

+ (NSIndexSet *)blockedIndexesForEntries:(NSArray *)entries
                                snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot {
    NSMutableIndexSet *blockedIndexes = [NSMutableIndexSet indexSet];
    NSUInteger childIndex = 0;

    for (id entry in entries) {
        BOOL removeChild =
            [NTYTProductionFilter shouldRemoveContentEntry:entry
                                                   snapshot:snapshot
                                                 childIndex:childIndex];
        if (removeChild) {
            [blockedIndexes addIndex:childIndex];
        }

        childIndex++;
    }

    return blockedIndexes;
}

+ (void)filterItemSectionCandidate:(YTIItemSectionRenderer *)section
                          snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot {
    id contentsValue = [section contentsArray];
    if (![contentsValue isKindOfClass:[NSArray class]]) {
        NTYTLog(@"[FilterDiag] keep section: contentsArray class=%@",
                contentsValue ? NSStringFromClass([contentsValue class]) : @"<nil>");
        return;
    }

    NSArray *contents = (NSArray *)contentsValue;
    if (contents.count == 0) {
        return;
    }

    NSIndexSet *blockedIndexes =
        [self blockedIndexesForEntries:contents snapshot:snapshot];
    if (blockedIndexes.count == 0) {
        return;
    }

    if (![contentsValue respondsToSelector:@selector(removeObjectsAtIndexes:)]) {
        NTYTLog(@"[FilterDiag] keep section: contentsArray is not mutable");
        return;
    }

    NSUInteger inputCount = contents.count;
    [(NSMutableArray *)contentsValue removeObjectsAtIndexes:blockedIndexes];

    NTYTLog(@"[Filter] item section direct commit: inputChildren=%lu retainedChildren=%lu removedChildren=%lu",
            (unsigned long)inputCount,
            (unsigned long)[(NSArray *)contentsValue count],
            (unsigned long)blockedIndexes.count);
}

+ (void)filterVerticalListRenderer:(YTIVerticalListRenderer *)verticalListRenderer
                          snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot {
    if (!verticalListRenderer ||
        ![verticalListRenderer respondsToSelector:@selector(itemsArray)]) {
        return;
    }

    id itemsValue = [verticalListRenderer itemsArray];
    if (![itemsValue isKindOfClass:[NSArray class]]) {
        NTYTLog(@"[FilterDiag] keep vertical list: itemsArray class=%@",
                itemsValue ? NSStringFromClass([itemsValue class]) : @"<nil>");
        return;
    }

    NSArray *items = (NSArray *)itemsValue;
    if (items.count == 0) {
        return;
    }

    NSIndexSet *blockedIndexes =
        [self blockedIndexesForEntries:items snapshot:snapshot];
    if (blockedIndexes.count == 0) {
        return;
    }

    if (![itemsValue respondsToSelector:@selector(removeObjectsAtIndexes:)]) {
        NTYTLog(@"[FilterDiag] keep vertical list: itemsArray is not mutable");
        return;
    }

    NSUInteger inputCount = items.count;
    [(NSMutableArray *)itemsValue removeObjectsAtIndexes:blockedIndexes];

    NTYTLog(@"[Filter] vertical list direct commit: inputChildren=%lu retainedChildren=%lu removedChildren=%lu",
            (unsigned long)inputCount,
            (unsigned long)[(NSArray *)itemsValue count],
            (unsigned long)blockedIndexes.count);
}

+ (void)filterShelfCandidateIfSupported:(YTIShelfRenderer *)candidate
                               snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot {
    if (![candidate respondsToSelector:@selector(content)]) return;
    YTIShelfSupportedRenderers *content = candidate.content;
    if (!content) return;

    SEL hasVerticalSelector =
        NSSelectorFromString(@"hasVerticalListRenderer");
    SEL hasHorizontalSelector =
        NSSelectorFromString(@"hasHorizontalListRenderer");

    if (![content respondsToSelector:hasVerticalSelector] ||
        ![content respondsToSelector:hasHorizontalSelector]) {
        return;
    }

    BOOL (*hasVerticalIMP)(id, SEL) =
        (BOOL (*)(id, SEL))[content methodForSelector:hasVerticalSelector];
    BOOL (*hasHorizontalIMP)(id, SEL) =
        (BOOL (*)(id, SEL))[content methodForSelector:hasHorizontalSelector];

    if (!hasVerticalIMP || !hasHorizontalIMP) return;

    BOOL verticalPresent =
        hasVerticalIMP(content, hasVerticalSelector);
    BOOL horizontalPresent =
        hasHorizontalIMP(content, hasHorizontalSelector);

    // A Shelf route must resolve uniquely before any direct mutation or whole-presentation commit.
    if (verticalPresent == horizontalPresent) return;

    if (verticalPresent) {
        YTIVerticalListRenderer *vertical = content.verticalListRenderer;
        if (!vertical) return;

        [self filterVerticalListRenderer:vertical snapshot:snapshot];
        return;
    }

    YTIHorizontalListRenderer *horizontal = content.horizontalListRenderer;
    if (!horizontal || ![horizontal respondsToSelector:@selector(itemsArray)]) return;
    id items = horizontal.itemsArray;
    if (![items isKindOfClass:[NSArray class]]) return;

    BOOL removeHorizontalItems =
        [NTYTProductionFilter shouldRemoveHorizontalListItems:(NSArray *)items
                                                     snapshot:snapshot];
    if (!removeHorizontalItems) return;

    if (![items respondsToSelector:@selector(removeObjectsAtIndexes:)]) {
        NTYTLog(@"[FilterDiag] keep horizontal shelf: itemsArray is not mutable");
        return;
    }

    SEL setHeaderRendererSelector =
        NSSelectorFromString(@"setHeaderRenderer:");
    if (![candidate respondsToSelector:setHeaderRendererSelector]) {
        NTYTLog(@"[FilterDiag] keep horizontal shelf: setHeaderRenderer: unavailable");
        return;
    }

    void (*setHeaderRendererIMP)(id, SEL, id) =
        (void (*)(id, SEL, id))[candidate methodForSelector:setHeaderRendererSelector];
    if (!setHeaderRendererIMP) {
        NTYTLog(@"[FilterDiag] keep horizontal shelf: setHeaderRenderer: IMP unavailable");
        return;
    }

    SEL hasFooterRendererSelector =
        NSSelectorFromString(@"hasFooterRenderer");
    if (![candidate respondsToSelector:hasFooterRendererSelector]) {
        NTYTLog(@"[FilterDiag] keep horizontal shelf: hasFooterRenderer unavailable");
        return;
    }

    BOOL (*hasFooterRendererIMP)(id, SEL) =
        (BOOL (*)(id, SEL))[candidate methodForSelector:hasFooterRendererSelector];
    if (!hasFooterRendererIMP) {
        NTYTLog(@"[FilterDiag] keep horizontal shelf: hasFooterRenderer IMP unavailable");
        return;
    }

    BOOL footerPresent =
        hasFooterRendererIMP(candidate, hasFooterRendererSelector);

    SEL setFooterRendererSelector =
        NSSelectorFromString(@"setFooterRenderer:");
    void (*setFooterRendererIMP)(id, SEL, id) = NULL;

    if (footerPresent) {
        if (![candidate respondsToSelector:setFooterRendererSelector]) {
            NTYTLog(@"[FilterDiag] keep horizontal shelf: setFooterRenderer: unavailable");
            return;
        }

        setFooterRendererIMP =
            (void (*)(id, SEL, id))[candidate methodForSelector:setFooterRendererSelector];
        if (!setFooterRendererIMP) {
            NTYTLog(@"[FilterDiag] keep horizontal shelf: setFooterRenderer: IMP unavailable");
            return;
        }
    }

    NSUInteger inputCount = [(NSArray *)items count];
    NSIndexSet *allIndexes =
        [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, inputCount)];

    [(NSMutableArray *)items removeObjectsAtIndexes:allIndexes];

    NSUInteger retainedCount = [(NSArray *)items count];
    if (retainedCount == 0) {
        setHeaderRendererIMP(candidate, setHeaderRendererSelector, nil);
        if (footerPresent) {
            setFooterRendererIMP(candidate, setFooterRendererSelector, nil);
        }
    }

    NTYTLog(@"[Filter] horizontal list empty commit: inputChildren=%lu retainedChildren=%lu removedChildren=%lu",
            (unsigned long)inputCount,
            (unsigned long)retainedCount,
            (unsigned long)(inputCount - retainedCount));
}

+ (void)filterSectionCollection:(NSArray *)sectionCollection {
    if (![sectionCollection isKindOfClass:[NSArray class]] || sectionCollection.count == 0) {
        return;
    }

    @try {
        NTYTRuntimeSettingsSnapshot *snapshot =
            [[NTYTSnapshotHolder sharedHolder] currentSnapshot];
        if (!snapshot) {
            return;
        }

        Class itemSectionClass = NSClassFromString(@"YTIItemSectionRenderer");
        Class shelfClass = NSClassFromString(@"YTIShelfRenderer");

        for (id candidate in sectionCollection) {
            @try {
                if (itemSectionClass && [candidate isKindOfClass:itemSectionClass]) {
                    [self filterItemSectionCandidate:(YTIItemSectionRenderer *)candidate
                                            snapshot:snapshot];
                } else if (shelfClass && [candidate isKindOfClass:shelfClass]) {
                    [self filterShelfCandidateIfSupported:(YTIShelfRenderer *)candidate
                                                  snapshot:snapshot];
                }
            } @catch (NSException *candidateException) {
                NTYTLog(@"[Filter] section candidate fail-open: %@",
                        candidateException.reason ?: @"<unknown>");
            }
        }
    } @catch (NSException *containerException) {
        NTYTLog(@"[Filter] section collection fail-open: %@",
                containerException.reason ?: @"<unknown>");
    }
}

+ (NSArray *)filteredStandaloneHorizontalContinuationContents:(NSArray *)contents {
    @try {
        if (![contents isKindOfClass:[NSArray class]] || contents.count == 0) return contents;
        NTYTRuntimeSettingsSnapshot *snapshot = [[NTYTSnapshotHolder sharedHolder] currentSnapshot];
        if (!snapshot) return contents;
        NSMutableArray *retained = [NSMutableArray arrayWithCapacity:contents.count];
        BOOL removed = NO;
        for (id element in contents) {
            if ([NTYTProductionFilter shouldRemoveStandaloneHorizontalElement:element snapshot:snapshot]) {
                removed = YES;
            } else {
                [retained addObject:element];
            }
        }
        // Keep original identity if nothing changed; otherwise preserve each retained object and order.
        return removed ? [retained copy] : contents;
    } @catch (__unused NSException *exception) {
        return contents;
    }
}

@end
