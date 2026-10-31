#import <Foundation/Foundation.h>

@class NTYTRuleListItem;

NS_ASSUME_NONNULL_BEGIN

@interface NTYTRuleListState : NSObject

@property(nonatomic, readonly) NSUInteger itemCount;
@property(nonatomic, readonly) NSUInteger visibleItemCount;
@property(nonatomic, copy, readonly) NSString *effectiveSearchQuery;
@property(nonatomic, readonly, getter=isSearchActive) BOOL searchActive;
@property(nonatomic, readonly) NSUInteger selectedCount;
@property(nonatomic, readonly, getter=areAllVisibleItemsSelected) BOOL allVisibleItemsSelected;

- (void)replaceItems:(NSArray<NTYTRuleListItem *> *)items;
- (void)updateSearchText:(NSString *)searchText;
- (nullable NTYTRuleListItem *)itemAtVisibleIndex:(NSUInteger)index;
- (nullable NTYTRuleListItem *)itemWithIdentifier:(NSUUID *)identifier;
- (BOOL)isIdentifierSelected:(NSUUID *)identifier;
- (void)setIdentifier:(NSUUID *)identifier selected:(BOOL)selected;
- (void)selectAllVisibleItems;
- (void)clearSelection;
- (NSArray<NSUUID *> *)selectedIdentifiersInVisibleOrder;
- (BOOL)moveVisibleItemFromIndex:(NSUInteger)fromIndex
                         toIndex:(NSUInteger)toIndex;

@end

NS_ASSUME_NONNULL_END
