#import "NTYTRuleListState.h"

#import "NTYTRuleListItem.h"

@interface NTYTRuleListState ()
@property(nonatomic, copy) NSArray<NTYTRuleListItem *> *itemSequence;
@property(nonatomic, copy) NSArray<NTYTRuleListItem *> *visibleItemSequence;
@property(nonatomic, copy, readwrite) NSString *effectiveSearchQuery;
@property(nonatomic, strong) NSMutableSet<NSUUID *> *selectedIdentifiers;
@end

@implementation NTYTRuleListState

- (instancetype)init {
    self = [super init];
    if (self) {
        _itemSequence = @[];
        _visibleItemSequence = @[];
        _effectiveSearchQuery = @"";
        _selectedIdentifiers = [NSMutableSet set];
    }
    return self;
}

- (NSUInteger)itemCount {
    return self.itemSequence.count;
}

- (NSUInteger)visibleItemCount {
    return self.visibleItemSequence.count;
}

- (BOOL)isSearchActive {
    return self.effectiveSearchQuery.length > 0;
}

- (NSUInteger)selectedCount {
    return self.selectedIdentifiers.count;
}

- (BOOL)areAllVisibleItemsSelected {
    return self.visibleItemCount > 0 && self.selectedCount == self.visibleItemCount;
}

- (void)replaceItems:(NSArray<NTYTRuleListItem *> *)items {
    self.itemSequence = items;
    [self rebuildVisibleItems];

    NSMutableSet<NSUUID *> *visibleIdentifiers = [NSMutableSet set];
    for (NTYTRuleListItem *item in self.visibleItemSequence) {
        [visibleIdentifiers addObject:item.identifier];
    }
    [self.selectedIdentifiers intersectSet:visibleIdentifiers];
}

- (void)updateSearchText:(NSString *)searchText {
    [self clearSelection];
    self.effectiveSearchQuery = [searchText stringByTrimmingCharactersInSet:
        [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [self rebuildVisibleItems];
}

- (void)rebuildVisibleItems {
    if (!self.isSearchActive) {
        self.visibleItemSequence = self.itemSequence;
        return;
    }

    NSMutableArray<NTYTRuleListItem *> *visibleItems = [NSMutableArray array];
    for (NTYTRuleListItem *item in self.itemSequence) {
        if ([item.text rangeOfString:self.effectiveSearchQuery
                             options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [visibleItems addObject:item];
        }
    }
    self.visibleItemSequence = visibleItems;
}

- (NTYTRuleListItem *)itemAtVisibleIndex:(NSUInteger)index {
    return index < self.visibleItemCount ? self.visibleItemSequence[index] : nil;
}

- (NTYTRuleListItem *)itemWithIdentifier:(NSUUID *)identifier {
    for (NTYTRuleListItem *item in self.itemSequence) {
        if ([item.identifier isEqual:identifier]) {
            return item;
        }
    }
    return nil;
}

- (BOOL)isIdentifierSelected:(NSUUID *)identifier {
    return [self.selectedIdentifiers containsObject:identifier];
}

- (void)setIdentifier:(NSUUID *)identifier selected:(BOOL)selected {
    if (selected) {
        [self.selectedIdentifiers addObject:identifier];
    } else {
        [self.selectedIdentifiers removeObject:identifier];
    }
}

- (void)selectAllVisibleItems {
    [self clearSelection];
    for (NTYTRuleListItem *item in self.visibleItemSequence) {
        [self.selectedIdentifiers addObject:item.identifier];
    }
}

- (void)clearSelection {
    [self.selectedIdentifiers removeAllObjects];
}

- (NSArray<NSUUID *> *)selectedIdentifiersInVisibleOrder {
    NSMutableArray<NSUUID *> *identifiers = [NSMutableArray array];
    for (NTYTRuleListItem *item in self.visibleItemSequence) {
        if ([self isIdentifierSelected:item.identifier]) {
            [identifiers addObject:item.identifier];
        }
    }
    return identifiers;
}

- (BOOL)moveVisibleItemFromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex {
    if (self.isSearchActive || fromIndex >= self.itemCount || toIndex >= self.itemCount) {
        return NO;
    }

    NSMutableArray<NTYTRuleListItem *> *items = [self.itemSequence mutableCopy];
    NTYTRuleListItem *item = items[fromIndex];
    [items removeObjectAtIndex:fromIndex];
    [items insertObject:item atIndex:toIndex];
    self.itemSequence = items;
    self.visibleItemSequence = self.itemSequence;
    return YES;
}

@end
