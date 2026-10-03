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

+ (BOOL)filterItemSectionCandidate:(YTIItemSectionRenderer *)section
                          snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot {
    id contentsValue = [section contentsArray];
    if (![contentsValue isKindOfClass:[NSArray class]]) {
        NTYTLog(@"[FilterDiag] keep section: contentsArray class=%@",
                contentsValue ? NSStringFromClass([contentsValue class]) : @"<nil>");
        return NO;
    }

    NSArray *contents = (NSArray *)contentsValue;
    if (contents.count == 0) {
        return NO;
    }

    NSIndexSet *blockedIndexes =
        [self blockedIndexesForEntries:contents snapshot:snapshot];
    if (blockedIndexes.count == 0) {
        return NO;
    }

    if (blockedIndexes.count == contents.count) {
        NTYTLog(@"[Filter] remove section: all %lu children blocked",
                (unsigned long)contents.count);
        return YES;
    }

    if (![contentsValue respondsToSelector:@selector(removeObjectsAtIndexes:)]) {
        NTYTLog(@"[FilterDiag] keep section: contentsArray is not mutable");
        return NO;
    }

    NSUInteger inputCount = contents.count;
    [(NSMutableArray *)contentsValue removeObjectsAtIndexes:blockedIndexes];

    NTYTLog(@"[Filter] item section direct commit: inputChildren=%lu retainedChildren=%lu removedChildren=%lu",
            (unsigned long)inputCount,
            (unsigned long)[(NSArray *)contentsValue count],
            (unsigned long)blockedIndexes.count);

    return NO;
}

+ (void)filterVerticalListRenderer:(id)verticalListRenderer
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

+ (void)filterShelfCandidateIfSupported:(id)candidate
                               snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot {
    if (![candidate respondsToSelector:@selector(content)]) {
        return;
    }

    YTIShelfSupportedRenderers *content =
        [(YTIShelfRenderer *)candidate content];
    if (!content) {
        return;
    }

    YTIVerticalListRenderer *verticalListRenderer =
        content.verticalListRenderer;
    if (!verticalListRenderer) {
        return;
    }

    [self filterVerticalListRenderer:verticalListRenderer snapshot:snapshot];
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

        Class itemSectionClass = NSClassFromString(@"YTIItemSectionRenderer");
        Class shelfClass = NSClassFromString(@"YTIShelfRenderer");

        NSMutableArray *filtered =
            [NSMutableArray arrayWithCapacity:originalCollection.count];
        BOOL removedAnyOuterSection = NO;

        for (id candidate in originalCollection) {
            BOOL removeCandidate = NO;

            @try {
                if (itemSectionClass && [candidate isKindOfClass:itemSectionClass]) {
                    removeCandidate =
                        [self filterItemSectionCandidate:(YTIItemSectionRenderer *)candidate
                                                snapshot:snapshot];
                } else if (shelfClass && [candidate isKindOfClass:shelfClass]) {
                    [self filterShelfCandidateIfSupported:candidate snapshot:snapshot];
                }
            } @catch (NSException *candidateException) {
                NTYTLog(@"[Filter] section candidate fail-open: %@",
                        candidateException.reason ?: @"<unknown>");
                removeCandidate = NO;
            }

            if (removeCandidate) {
                removedAnyOuterSection = YES;
            } else {
                [filtered addObject:candidate];
            }
        }

        if (!removedAnyOuterSection) {
            return originalCollection;
        }

        return filtered;
    } @catch (NSException *containerException) {
        NTYTLog(@"[Filter] section collection fail-open: %@",
                containerException.reason ?: @"<unknown>");
        return originalCollection;
    }
}

@end
