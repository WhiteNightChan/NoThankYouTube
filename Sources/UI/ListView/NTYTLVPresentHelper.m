#import "NTYTLVPresentHelper.h"
#import "NTYTLVPrivate.h"
#import "NTYTLVSelectHelper.h"
#import "NTYTLVSetupHelper.h"
#import "UI/NTYTListEditingAdapter.h"
#import "UI/NTYTUIStrings.h"

@implementation NTYTRuleListViewController (NTYTLVPresentHelper)

- (BOOL)shouldShowSearchBar {
    return self.isSearching || self.items.count > 0;
}

- (UILabel *)emptyStateLabelWithText:(NSString *)text {
    UILabel *label = [UILabel new];
    label.text = text;
    label.textColor = UIColor.secondaryLabelColor;
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;
    return label;
}

- (void)updateSearchBarVisibilityIfNeeded {
    if ([self shouldShowSearchBar]) {
        if (self.searchBar.frame.size.height != 56.0) {
            self.searchBar.frame = CGRectMake(0, 0, 0, 56.0);
        }
        if (self.tableView.tableHeaderView != self.searchBar) {
            self.tableView.tableHeaderView = self.searchBar;
        }
    } else {
        [self.searchBar resignFirstResponder];
        self.tableView.tableHeaderView = nil;
    }
}

- (void)updateEmptyStateIfNeeded {
    [self updateSearchBarVisibilityIfNeeded];
    NSString *text = nil;
    if (self.isSearching && self.filteredItems.count == 0) {
        text = NTYTNoResultsText();
    } else if (!self.isSearching && self.items.count == 0) {
        text = NTYTEmptyListText();
    }
    self.tableView.backgroundView = text ? [self emptyStateLabelWithText:text] : nil;
}

- (NSInteger)currentVisibleItemCount {
    return self.isSearching ? self.filteredItems.count : self.items.count;
}

- (NSString *)currentCountDisplayText {
    NSInteger visible = [self currentVisibleItemCount];
    if (self.tableView.editing) {
        return [NSString stringWithFormat:@"%ld/%ld",
                                          (long)[self currentSelectedCount],
                                          (long)visible];
    }
    return [NSString stringWithFormat:@"%ld", (long)visible];
}

- (UIBarButtonItem *)titleBarButtonItem {
    UILabel *label = [UILabel new];
    label.text = self.titleText;
    label.textColor = UIColor.labelColor;
    label.font = [UIFont fontWithName:@"YouTubeSans-Bold" size:20.0]
        ?: [UIFont boldSystemFontOfSize:20.0];
    [label sizeToFit];
    CGFloat offset = -4.0;
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0,
                                                                 label.bounds.size.width - offset,
                                                                 44.0)];
    container.userInteractionEnabled = NO;
    CGRect frame = label.frame;
    frame.origin.x = offset;
    frame.origin.y = floor((44.0 - frame.size.height) / 2.0);
    label.frame = frame;
    [container addSubview:label];
    return [[UIBarButtonItem alloc] initWithCustomView:container];
}

- (NSArray<UIBarButtonItem *> *)rightBarButtonItemsForEditing:(BOOL)editing
                                             countDisplayText:(NSString *)countDisplayText {
    UIBarButtonItem *space = [self fixedSpaceBarButtonItemWithWidth:12.5];
    UIBarButtonItem *count = [self textBarButtonItemWithTitle:countDisplayText
                                                   textColor:UIColor.labelColor
                                                  fontWeight:UIFontWeightMedium
                                                      target:nil
                                                      action:nil];
    if (![self.editingAdapter mutationsAllowed]) {
        return @[space, count];
    }
    UIBarButtonItem *edit = [self editBarButtonItemForEditing:editing];
    if (editing) {
        return @[space, edit, count];
    }
    return @[space, edit, [self addBarButtonItem], count];
}

- (void)updateRightBarButtonItemsForCurrentState {
    self.navigationItem.rightBarButtonItems =
        [self rightBarButtonItemsForEditing:self.tableView.editing
                           countDisplayText:[self currentCountDisplayText]];
}

- (void)updateReadOnlyPresentation {
    if ([self.editingAdapter mutationsAllowed]) {
        self.navigationItem.prompt = nil;
    } else {
        self.navigationItem.prompt =
            [NSString stringWithFormat:@"Read-only — %@",
                NTYTSettingsLifecycleDescription([self.editingAdapter lifecycleState])];
        if (self.tableView.editing) {
            [self.tableView setEditing:NO animated:NO];
            [self.navigationController setToolbarHidden:YES animated:NO];
        }
    }
    [self updateRightBarButtonItemsForCurrentState];
}

@end
