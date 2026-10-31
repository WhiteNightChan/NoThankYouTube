#import "NTYTRuleListVCPresentation.h"

#import "NTYTRuleListVCInternal.h"
#import "NTYTRuleListState.h"
#import "UI/NTYTSettingsCell.h"
#import "UI/NTYTTransientMessagePresenter.h"

#import "Localization/NTYTUIStrings.h"

@implementation NTYTRuleListViewController (Presentation)

- (void)configureListPresentation {
    self.hasAppliedInitialSearchBarOffset = NO;
    self.initialTableViewOffsetY = CGFLOAT_MAX;

    [self configureTableViewAppearance];
    [self.tableView registerClass:NTYTSettingsCell.class
           forCellReuseIdentifier:@"NTYTSettingsCell"];
    self.tableView.rowHeight = UITableViewAutomaticDimension;

    self.searchBar = [self configuredSearchBar];
    self.tableView.tableHeaderView = self.searchBar;

    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.leftBarButtonItems = @[
        [self backBarButtonItem],
        [self titleBarButtonItem],
    ];
    self.navigationItem.rightBarButtonItems =
        [self rightBarButtonItemsForEditing:NO
                           countDisplayText:[self currentCountDisplayText]];

    [self configureToolbarItems];
    [self.navigationController setToolbarHidden:YES animated:NO];
    [self updateInteractivePopGestureEnabled];
    [self configureLongPressGesture];
}

- (void)refreshPresentationForCurrentState {
    [self updateEmptyStateForCurrentState];
    [self updateToolbarForCurrentState];
    [self updateNavigationItemsForCurrentState];
}

- (void)updateNavigationItemsForCurrentState {
    self.navigationItem.prompt = [self currentListMutationsAllowed]
        ? nil : NTYTReadOnlyText([self currentSettingsLifecycleState]);
    self.navigationItem.rightBarButtonItems =
        [self rightBarButtonItemsForEditing:self.tableView.editing
                           countDisplayText:[self currentCountDisplayText]];
}

- (void)updateToolbarVisibilityAnimated:(BOOL)animated {
    [self.navigationController setToolbarHidden:!self.tableView.editing animated:animated];
}

- (void)configureTableViewAppearance {
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.tableFooterView = [UIView new];
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
}

- (UISearchBar *)configuredSearchBar {
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 0, 56.0)];
    searchBar.delegate = self;
    searchBar.placeholder = NTYTSearchPlaceholder();
    searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    searchBar.smartQuotesType = UITextSmartQuotesTypeNo;
    searchBar.smartDashesType = UITextSmartDashesTypeNo;
    searchBar.smartInsertDeleteType = UITextSmartInsertDeleteTypeNo;
    searchBar.returnKeyType = UIReturnKeyDone;
    searchBar.searchBarStyle = UISearchBarStyleMinimal;
    searchBar.backgroundImage = [UIImage new];
    searchBar.backgroundColor = UIColor.clearColor;
    searchBar.barTintColor = UIColor.clearColor;
    searchBar.translucent = YES;
    return searchBar;
}

- (void)configureLongPressGesture {
    UILongPressGestureRecognizer *gesture =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    gesture.delegate = self;
    [self.tableView addGestureRecognizer:gesture];
}

- (UIBarButtonItem *)fixedSpaceBarButtonItemWithWidth:(CGFloat)width {
    UIBarButtonItem *space =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                     target:nil
                                                     action:nil];
    space.width = width;
    return space;
}

- (UIBarButtonItem *)backBarButtonItem {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImageSymbolConfiguration *configuration =
        [UIImageSymbolConfiguration configurationWithPointSize:18.5
                                                       weight:UIImageSymbolWeightLight];
    UIImage *image = [[UIImage systemImageNamed:@"chevron.left"
                               withConfiguration:configuration]
        imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [button setImage:image forState:UIControlStateNormal];
    button.tintColor = UIColor.labelColor;
    button.frame = CGRectMake(0, 0, 42, 44);
    [button addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 42, 44)];
    [container addSubview:button];
    return [[UIBarButtonItem alloc] initWithCustomView:container];
}

- (UIBarButtonItem *)textBarButtonItemWithTitle:(NSString *)title
                                      textColor:(UIColor *)textColor
                                     fontWeight:(UIFontWeight)fontWeight
                                         target:(id)target
                                         action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title ?: @"" forState:UIControlStateNormal];
    [button setTitleColor:textColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:17.0 weight:fontWeight];
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [button sizeToFit];
    CGRect frame = button.frame;
    frame.size.width = ceil(CGRectGetWidth(frame));
    frame.size.height = 32.0;
    button.frame = frame;
    if (target && action) {
        [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    } else {
        button.userInteractionEnabled = NO;
    }
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 32.0)];
    container.userInteractionEnabled = target != nil;
    [container addSubview:button];
    return [[UIBarButtonItem alloc] initWithCustomView:container];
}

- (UIBarButtonItem *)symbolBarButtonItemWithSystemName:(NSString *)systemName
                                             tintColor:(UIColor *)tintColor
                                                target:(id)target
                                                action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(0, 0, 22.5, 32.0);
    UIImageSymbolConfiguration *configuration =
        [UIImageSymbolConfiguration configurationWithPointSize:17.0
                                                       weight:UIImageSymbolWeightRegular];
    UIImage *image = [[UIImage systemImageNamed:systemName withConfiguration:configuration]
        imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [button setImage:image forState:UIControlStateNormal];
    button.tintColor = tintColor;
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    UIView *container = [[UIView alloc] initWithFrame:button.bounds];
    [container addSubview:button];
    return [[UIBarButtonItem alloc] initWithCustomView:container];
}

- (UIBarButtonItem *)addBarButtonItem {
    return [self symbolBarButtonItemWithSystemName:@"plus"
                                         tintColor:UIColor.labelColor
                                            target:self
                                            action:@selector(addButtonTapped)];
}

- (UIBarButtonItem *)editBarButtonItemForEditing:(BOOL)editing {
    return [self textBarButtonItemWithTitle:(editing ? NTYTDoneTitle() : NTYTEditActionTitle())
                                  textColor:UIColor.labelColor
                                 fontWeight:UIFontWeightRegular
                                     target:self
                                     action:@selector(editButtonTapped)];
}

- (void)configureToolbarItems {
    UIBarButtonItem *selectAll = [[UIBarButtonItem alloc] initWithTitle:NTYTSelectAllTitle()
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(selectAllButtonTapped)];
    selectAll.tintColor = UIColor.systemBlueColor;

    UIBarButtonItem *space =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                     target:nil
                                                     action:nil];
    UIBarButtonItem *deleteButton = [[UIBarButtonItem alloc] initWithTitle:NTYTDeleteActionTitle()
                                                                      style:UIBarButtonItemStylePlain
                                                                     target:self
                                                                     action:@selector(deleteSelectedItemsTapped)];
    deleteButton.tintColor = UIColor.systemRedColor;
    selectAll.enabled = NO;
    deleteButton.enabled = NO;
    self.toolbarItems = @[selectAll, space, deleteButton];
}

- (BOOL)shouldApplyInitialSearchBarOffset {
    if (self.hasAppliedInitialSearchBarOffset ||
        self.tableView.tableHeaderView != self.searchBar ||
        self.searchBar.text.length > 0 || self.state.isSearchActive) {
        return NO;
    }
    return CGRectGetHeight(self.searchBar.frame) > 0.0;
}

- (void)applyInitialSearchBarOffsetIfNeeded {
    if (self.initialTableViewOffsetY == CGFLOAT_MAX) {
        self.initialTableViewOffsetY = self.tableView.contentOffset.y;
    }
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

- (BOOL)shouldShowSearchBar {
    return self.state.isSearchActive || self.state.itemCount > 0;
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

- (void)updateSearchBarVisibilityForCurrentState {
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

- (void)updateEmptyStateForCurrentState {
    [self updateSearchBarVisibilityForCurrentState];
    NSString *text = nil;
    if (self.state.isSearchActive && self.state.visibleItemCount == 0) {
        text = NTYTNoResultsText();
    } else if (!self.state.isSearchActive && self.state.itemCount == 0) {
        text = NTYTEmptyListText();
    }
    self.tableView.backgroundView = text ? [self emptyStateLabelWithText:text] : nil;
}

- (NSString *)currentCountDisplayText {
    NSInteger visible = self.state.visibleItemCount;
    if (self.tableView.editing) {
        return [NSString stringWithFormat:@"%ld/%ld",
                                          (long)self.state.selectedCount,
                                          (long)visible];
    }
    return NTYTRuleCountText((NSUInteger)visible);
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
    if (![self currentListMutationsAllowed]) {
        return @[space, count];
    }
    UIBarButtonItem *edit = [self editBarButtonItemForEditing:editing];
    if (editing) {
        return @[space, edit, count];
    }
    return @[space, edit, [self addBarButtonItem], count];
}

- (void)updateToolbarForCurrentState {
    if (self.toolbarItems.count < 3) {
        return;
    }

    NSInteger total = self.state.visibleItemCount;
    NSInteger selected = (self.tableView.editing ? self.state.selectedCount : 0);
    UIBarButtonItem *selectAll = self.toolbarItems[0];
    UIBarButtonItem *deleteButton = self.toolbarItems[2];
    BOOL mutable = [self currentListMutationsAllowed];
    selectAll.enabled = mutable && self.tableView.editing && total > 0;
    deleteButton.enabled = mutable && selected > 0;
    selectAll.title = self.state.areAllVisibleItemsSelected ? NTYTDeselectAllTitle() : NTYTSelectAllTitle();
}

- (NTYTSettingsCell *)estimatedSizingCell {
    if (!self.sizingCell) {
        self.sizingCell = [[NTYTSettingsCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                reuseIdentifier:nil];
    }
    return self.sizingCell;
}

- (CGFloat)heightForRuleText:(NSString *)text {
    UITableView *tableView = self.tableView;
    CGFloat width = CGRectGetWidth(tableView.bounds);
    if (width <= 0.0) {
        return 44.0;
    }
    NTYTSettingsCell *cell = [self estimatedSizingCell];
    [cell configureWithText:text ?: @""];
    [cell setEditing:tableView.editing animated:NO];
    cell.bounds = CGRectMake(0, 0, width, CGFLOAT_MAX);
    [cell setNeedsLayout];
    [cell layoutIfNeeded];
    CGSize target = CGSizeMake(width, UILayoutFittingCompressedSize.height);
    CGFloat height =
        [cell.contentView systemLayoutSizeFittingSize:target
                 withHorizontalFittingPriority:UILayoutPriorityRequired
                       verticalFittingPriority:UILayoutPriorityFittingSizeLevel].height;
    return MAX(height, 1.0);
}

- (void)presentFailureMessage:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NTYTAppName()
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NTYTOKTitle() style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)presentCopyFeedbackForText:(NSString *)text {
    [NTYTTransientMessagePresenter showMessage:NTYTCopiedRuleText(text)
                             inViewController:self];
}

@end
