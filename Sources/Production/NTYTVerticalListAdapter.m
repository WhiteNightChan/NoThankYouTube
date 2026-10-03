#import "NTYTVerticalListAdapter.h"

#import "Core/NTYTRuntimeModel.h"
#import "Core/NTYTSnapshotHolder.h"
#import "NTYTProductionFilter.h"
#import "Debug/LogHelper.h"

@implementation NTYTVerticalListAdapter

+ (NSArray *)filteredItemsFromOriginal:(NSArray *)originalItems {
    if (![originalItems isKindOfClass:[NSArray class]] || originalItems.count == 0) {
        return originalItems;
    }

    @try {
        NTYTRuntimeSettingsSnapshot *snapshot =
            [[NTYTSnapshotHolder sharedHolder] currentSnapshot];
        if (!snapshot) {
            return originalItems;
        }

        NSMutableArray *retainedChildren =
            [NSMutableArray arrayWithCapacity:originalItems.count];
        BOOL removedAnyChild = NO;
        NSUInteger childIndex = 0;

        for (id entry in originalItems) {
            BOOL removeChild =
                [NTYTProductionFilter shouldRemoveContentEntry:entry
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
            return originalItems;
        }

        if (retainedChildren.count == 0) {
            NTYTLog(@"[Filter] vertical list empty commit: all %lu children blocked",
                    (unsigned long)originalItems.count);
            return retainedChildren;
        }

        NTYTLog(@"[Filter] vertical list filtered: inputChildren=%lu retainedChildren=%lu",
                (unsigned long)originalItems.count,
                (unsigned long)retainedChildren.count);

        return retainedChildren;
    } @catch (NSException *containerException) {
        NTYTLog(@"[Filter] vertical list rollback: %@",
                containerException.reason ?: @"<unknown>");
        return originalItems;
    }
}

@end
