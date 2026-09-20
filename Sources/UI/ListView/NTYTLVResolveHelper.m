#import "NTYTLVResolveHelper.h"
#import "NTYTLVPrivate.h"
#import "UI/NTYTRuleListItem.h"

@implementation NTYTRuleListViewController (NTYTLVResolveHelper)

- (NTYTRuleListItem *)resolvedItemForIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath) {
        return nil;
    }
    NSArray<NTYTRuleListItem *> *source = self.isSearching ? self.filteredItems : self.items;
    if (indexPath.row < 0 || indexPath.row >= source.count) {
        return nil;
    }
    NTYTRuleListItem *visibleItem = source[indexPath.row];
    return [self itemWithIdentifier:visibleItem.identifier];
}

- (NTYTRuleListItem *)itemWithIdentifier:(NSUUID *)identifier {
    for (NTYTRuleListItem *item in self.items) {
        if ([item.identifier isEqual:identifier]) {
            return item;
        }
    }
    return nil;
}

- (NSArray<NSUUID *> *)resolvedIdentifiersForIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    NSMutableArray<NSUUID *> *identifiers = [NSMutableArray array];
    for (NSIndexPath *indexPath in indexPaths) {
        NTYTRuleListItem *item = [self resolvedItemForIndexPath:indexPath];
        if (item.identifier) {
            [identifiers addObject:item.identifier];
        }
    }
    return identifiers;
}

@end
