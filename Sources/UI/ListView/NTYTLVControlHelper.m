#import "NTYTLVControlHelper.h"
#import "NTYTLVPrivate.h"

@implementation NTYTRuleListViewController (NTYTLVControlHelper)

- (BOOL)shouldApplyInitialSearchBarOffset {
    if (self.hasAppliedInitialSearchBarOffset ||
        self.tableView.tableHeaderView != self.searchBar ||
        self.searchBar.text.length > 0 || self.isSearching) {
        return NO;
    }
    return CGRectGetHeight(self.searchBar.frame) > 0.0;
}

- (void)applyInitialSearchBarOffsetIfNeeded {
    if (![self shouldApplyInitialSearchBarOffset]) {
        return;
    }
    CGPoint offset = self.tableView.contentOffset;
    offset.y = self.initialTableViewOffsetY + CGRectGetHeight(self.searchBar.frame);
    [self.tableView setContentOffset:offset animated:NO];
    self.hasAppliedInitialSearchBarOffset = YES;
}

- (void)updateInteractivePopGestureEnabled {
    UIGestureRecognizer *gesture = self.navigationController.interactivePopGestureRecognizer;
    if (gesture) {
        gesture.enabled = !self.tableView.editing;
    }
}

@end
