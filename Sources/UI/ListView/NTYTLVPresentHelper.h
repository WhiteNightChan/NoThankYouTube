#import "NTYTRuleListViewController.h"

@interface NTYTRuleListViewController (NTYTLVPresentHelper)
- (BOOL)shouldShowSearchBar;
- (UILabel *)emptyStateLabelWithText:(NSString *)text;
- (void)updateSearchBarVisibilityIfNeeded;
- (void)updateEmptyStateIfNeeded;
- (NSInteger)currentVisibleItemCount;
- (NSString *)currentCountDisplayText;
- (void)updateRightBarButtonItemsForCurrentState;
- (UIBarButtonItem *)titleBarButtonItem;
- (NSArray<UIBarButtonItem *> *)rightBarButtonItemsForEditing:(BOOL)editing
                                             countDisplayText:(NSString *)countDisplayText;
- (void)updateReadOnlyPresentation;
@end
