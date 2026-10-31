#import "NTYTRuleListViewController.h"

@class NTYTRuleListItem;

NS_ASSUME_NONNULL_BEGIN

@interface NTYTRuleListViewController (Editing)

- (void)addButtonTapped;
- (void)editButtonTapped;
- (void)selectAllButtonTapped;
- (void)deleteSelectedItemsTapped;
- (void)beginEditingRuleItem:(NTYTRuleListItem *)item;
- (void)requestDeleteRuleItem:(NTYTRuleListItem *)item;
- (void)requestMoveRuleItem:(NTYTRuleListItem *)item
                    toIndex:(NSUInteger)destinationIndex;
- (void)leaveEditingModeClearingSelectionAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
