#import "NTYTRuleListViewController.h"

@interface NTYTRuleListViewController (NTYTLVSelectHelper)
- (NSInteger)currentSelectedCount;
- (void)clearEditingSelectionForSearchRefresh;
- (void)updateSelectionToolbarButtonsForCurrentState;
- (void)selectAllToolbarButtonTapped;
@end
