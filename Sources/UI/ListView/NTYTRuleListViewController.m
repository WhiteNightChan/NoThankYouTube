#import "NTYTRuleListViewController.h"

#import "NTYTLVPrivate.h"
#import "NTYTLVTextCell.h"
#import "NTYTLVControlHelper.h"
#import "NTYTLVDeleteFlowHelper.h"
#import "NTYTLVInputHelper.h"
#import "NTYTLVMeasureHelper.h"
#import "NTYTLVPresentHelper.h"
#import "NTYTLVResolveHelper.h"
#import "NTYTLVSearchHelper.h"
#import "NTYTLVSelectHelper.h"
#import "NTYTLVSetupHelper.h"
#import "UI/NTYTListEditingAdapter.h"
#import "UI/NTYTRuleListItem.h"
#import "UI/NTYTUIStrings.h"
#import "Persistence/NTYTSettingsCoordinator.h"

@implementation NTYTRuleListViewController

- (instancetype)initWithListID:(NTYTListID)listID title:(NSString *)title {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _listID = listID;
        _titleText = [title copy];
        _editingAdapter = [[NTYTListEditingAdapter alloc] initWithListID:listID];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self loadItemsFromAuthoritativeSource];
    self.filteredItems = [NSMutableArray array];
    self.searchText = @"";
    self.isSearching = NO;
    self.hasAppliedInitialSearchBarOffset = NO;
    self.initialTableViewOffsetY = CGFLOAT_MAX;

    [self configureTableViewAppearance];
    [self.tableView registerClass:NTYTLVTextCell.class
           forCellReuseIdentifier:@"NTYTLVTextCell"];
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
    [self updateReadOnlyPresentation];
    [self updateEmptyStateIfNeeded];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadItemsFromAuthoritativeSource];
    [self reloadListDataForCurrentState];
    [self refreshListUIForCurrentState];
    [self updateReadOnlyPresentation];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.initialTableViewOffsetY == CGFLOAT_MAX) {
        self.initialTableViewOffsetY = self.tableView.contentOffset.y;
    }
    [self applyInitialSearchBarOffsetIfNeeded];
}

- (void)loadItemsFromAuthoritativeSource {
    self.items = [[self.editingAdapter loadItems] mutableCopy];
}

- (void)reloadListDataForCurrentState {
    [self rebuildFilteredItemsForCurrentSearchText];
    [self.tableView reloadData];
}

- (void)refreshListUIForCurrentState {
    [self updateEmptyStateIfNeeded];
    [self updateSelectionUIForCurrentState];
}

- (void)updateSelectionUIForCurrentState {
    [self updateSelectionToolbarButtonsForCurrentState];
    [self updateRightBarButtonItemsForCurrentState];
}

- (void)goBack {
    if (self.tableView.editing) {
        [self.tableView setEditing:NO animated:NO];
    }
    [self updateInteractivePopGestureEnabled];
    [self.navigationController setToolbarHidden:YES animated:NO];
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.isSearching ? self.filteredItems.count : self.items.count;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NTYTRuleListItem *item = [self resolvedItemForIndexPath:indexPath];
    return item ? [self estimatedHeightForDisplayText:item.text tableView:tableView] : 44.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NTYTLVTextCell *cell =
        [tableView dequeueReusableCellWithIdentifier:@"NTYTLVTextCell"
                                        forIndexPath:indexPath];
    NTYTRuleListItem *item = [self resolvedItemForIndexPath:indexPath];
    [cell configureWithText:item.text ?: @""];
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.editing) {
        [self updateSelectionUIForCurrentState];
        return;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (![self.editingAdapter mutationsAllowed]) {
        return;
    }
    NTYTRuleListItem *item = [self resolvedItemForIndexPath:indexPath];
    if (item) {
        [self presentEditInputAlertForItem:item draft:item.text diagnostic:nil];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.editing) {
        [self updateSelectionUIForCurrentState];
    }
}

- (void)addButtonTapped {
    if ([self.editingAdapter mutationsAllowed]) {
        [self presentAddInputAlertWithDraft:nil diagnostic:nil];
    }
}

- (void)editButtonTapped {
    if (![self.editingAdapter mutationsAllowed]) {
        return;
    }
    BOOL editing = !self.tableView.editing;
    if (editing) {
        [self.searchBar resignFirstResponder];
    }
    [self.tableView setEditing:editing animated:YES];
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
    if (!editing && !self.tableView.editing) {
        [self.tableView beginUpdates];
        [self.tableView endUpdates];
    }
    [self updateSelectionUIForCurrentState];
    [self updateInteractivePopGestureEnabled];
    [self.navigationController setToolbarHidden:!editing animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return !self.isSearching && [self.editingAdapter mutationsAllowed];
}

- (void)tableView:(UITableView *)tableView
moveRowAtIndexPath:(NSIndexPath *)fromIndexPath
      toIndexPath:(NSIndexPath *)toIndexPath {
    if (self.isSearching || fromIndexPath.row >= self.items.count || toIndexPath.row >= self.items.count) {
        [self loadItemsFromAuthoritativeSource];
        [self reloadListDataForCurrentState];
        return;
    }

    NTYTRuleListItem *item = self.items[fromIndexPath.row];
    [self.items removeObjectAtIndex:fromIndexPath.row];
    [self.items insertObject:item atIndex:toIndexPath.row];

    NTYTMutationResult *result =
        [self.editingAdapter moveIdentifier:item.identifier toIndex:(NSUInteger)toIndexPath.row];
    [self loadItemsFromAuthoritativeSource];
    [self clearEditingSelectionForSearchRefresh];
    [self reloadListDataForCurrentState];
    [self refreshListUIForCurrentState];
    if (!result.isSuccess) {
        [self presentFailureMessage:result.message];
    }
}

- (void)showTransientMessage:(NSString *)message {
    if (message.length == 0) {
        return;
    }
    UILabel *label = [UILabel new];
    label.text = message;
    label.textColor = UIColor.whiteColor;
    label.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.78];
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;
    label.layer.cornerRadius = 8.0;
    label.layer.masksToBounds = YES;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
        [label.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [label.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-20.0],
        [label.widthAnchor constraintLessThanOrEqualToAnchor:self.view.widthAnchor multiplier:0.82],
    ]];
    [UIView animateWithDuration:0.2
                          delay:1.2
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{ label.alpha = 0.0; }
                     completion:^(__unused BOOL finished) { [label removeFromSuperview]; }];
}

- (void)presentFailureMessage:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"NoThankYouTube"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateBegan || self.tableView.editing) {
        return;
    }
    NSIndexPath *indexPath =
        [self.tableView indexPathForRowAtPoint:[gesture locationInView:self.tableView]];
    NTYTRuleListItem *item = [self resolvedItemForIndexPath:indexPath];
    if (!item) {
        return;
    }
    UIPasteboard.generalPasteboard.string = item.text;
    [self showTransientMessage:@"Copied"];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return !self.tableView.editing;
}

@end
