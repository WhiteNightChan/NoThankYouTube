#import "NTYTRuleListViewController.h"

@interface NTYTRuleListViewController (NTYTLVSearchHelper)
- (void)applySearchStateForText:(NSString *)searchText;
- (void)rebuildFilteredItemsForCurrentSearchText;
@end
