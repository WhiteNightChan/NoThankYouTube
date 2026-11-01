#import "NTYTSectionCollectionAdapter.h"

#import <YouTubeHeader/YTIHorizontalListRenderer.h>
#import <YouTubeHeader/YTIItemSectionRenderer.h>
#import <YouTubeHeader/YTIShelfRenderer.h>
#import <YouTubeHeader/YTIShelfSupportedRenderers.h>
#import <YouTubeHeader/YTIVerticalListRenderer.h>

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

+ (void)filterHorizontalListRenderer:(YTIHorizontalListRenderer *)horizontal
                               shelf:(YTIShelfRenderer *)shelf
                            snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot {
    if (!horizontal ||
        ![horizontal respondsToSelector:@selector(itemsArray)]) {
        return;
    }

    id itemsValue = horizontal.itemsArray;
    if (![itemsValue isKindOfClass:[NSArray class]]) {
        return;
    }

    NSArray *items = (NSArray *)itemsValue;

    BOOL removeHorizontalItems =
        [NTYTProductionFilter shouldRemoveHorizontalListItems:items
                                                     snapshot:snapshot];
    if (!removeHorizontalItems) return;

    if (![itemsValue respondsToSelector:@selector(removeObjectsAtIndexes:)]) {
        NTYTLog(@"[FilterDiag] keep horizontal shelf: itemsArray is not mutable");
        return;
    }

    if (![shelf respondsToSelector:@selector(setHeaderRenderer:)]) {
        NTYTLog(@"[FilterDiag] keep horizontal shelf: setHeaderRenderer: unavailable");
        return;
    }

    if (![shelf respondsToSelector:@selector(hasFooterRenderer)]) {
        NTYTLog(@"[FilterDiag] keep horizontal shelf: hasFooterRenderer unavailable");
        return;
    }

    BOOL footerPresent = shelf.hasFooterRenderer;

    if (footerPresent &&
        ![shelf respondsToSelector:@selector(setFooterRenderer:)]) {
        NTYTLog(@"[FilterDiag] keep horizontal shelf: setFooterRenderer: unavailable");
        return;
    }

    NSUInteger inputCount = items.count;
    NSIndexSet *allIndexes =
        [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, inputCount)];

    [(NSMutableArray *)itemsValue removeObjectsAtIndexes:allIndexes];

    NSUInteger retainedCount = [(NSArray *)itemsValue count];
    if (retainedCount == 0) {
        shelf.headerRenderer = nil;

        if (footerPresent) {
            shelf.footerRenderer = nil;
        }
    }

    NTYTLog(@"[Filter] horizontal list empty commit: inputChildren=%lu retainedChildren=%lu removedChildren=%lu",
            (unsigned long)inputCount,
            (unsigned long)retainedCount,
            (unsigned long)(inputCount - retainedCount));
}

+ (void)filterShelfCandidateIfSupported:(YTIShelfRenderer *)candidate
                               snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot {
    if (![candidate respondsToSelector:@selector(content)]) return;

    YTIShelfSupportedRenderers *content = candidate.content;
    if (!content) return;

    if (![content respondsToSelector:@selector(hasVerticalListRenderer)] ||
        ![content respondsToSelector:@selector(hasHorizontalListRenderer)]) {
        return;
    }

    BOOL verticalPresent = content.hasVerticalListRenderer;
    BOOL horizontalPresent = content.hasHorizontalListRenderer;

    // A Shelf route must resolve uniquely before any direct mutation or whole-presentation commit.
    if (verticalPresent == horizontalPresent) return;

    if (verticalPresent) {
        YTIVerticalListRenderer *vertical = content.verticalListRenderer;
        if (!vertical) return;

        [self filterVerticalListRenderer:vertical snapshot:snapshot];
        return;
    }

    [self filterHorizontalListRenderer:content.horizontalListRenderer
                                 shelf:candidate
                              snapshot:snapshot];
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
