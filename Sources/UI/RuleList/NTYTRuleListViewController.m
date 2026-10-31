#import "NTYTRuleListViewController.h"

#import "NTYTRuleListVCInternal.h"
#import "NTYTRuleListItem.h"
#import "NTYTRuleListState.h"
#import "NTYTRuleListVCEditing.h"
#import "NTYTRuleListVCPresentation.h"
#import "UI/NTYTListEditingAdapter.h"
#import "UI/NTYTSettingsCell.h"

@implementation NTYTRuleListViewController

- (instancetype)initWithListID:(NTYTListID)listID title:(NSString *)title {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _listID = listID;
        _titleText = [title copy];
        _editingAdapter = [[NTYTListEditingAdapter alloc] initWithListID:listID];
        _state = [NTYTRuleListState new];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.state replaceItems:[self.editingAdapter loadItems]];
    [self configureListPresentation];
    [self refreshPresentationForCurrentState];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadAuthoritativeStateAndRender];
    [self synchronizeEditingStateWithMutationAvailability];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self applyInitialSearchBarOffsetIfNeeded];
}

- (void)reloadAuthoritativeStateAndRender {
    [self.state replaceItems:[self.editingAdapter loadItems]];
    [self renderCurrentState];
}

- (void)renderCurrentState {
    [self.tableView reloadData];
    [self applySelectionProjectionToTableView];
    [self refreshPresentationForCurrentState];
}

- (void)applySelectionProjectionToTableView {
    // UIKit selection is only a projection; never read it back as Rule identity.
    for (NSIndexPath *indexPath in [self.tableView.indexPathsForSelectedRows copy] ?: @[]) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
    if (!self.tableView.editing) {
        return;
    }

    for (NSUInteger row = 0; row < self.state.visibleItemCount; row++) {
        NTYTRuleListItem *item = [self.state itemAtVisibleIndex:row];
        if ([self.state isIdentifierSelected:item.identifier]) {
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:(NSInteger)row inSection:0]
                                      animated:NO
                                scrollPosition:UITableViewScrollPositionNone];
        }
    }
}

- (BOOL)currentListMutationsAllowed {
    return [self.editingAdapter mutationsAllowed];
}

- (NTYTSettingsLifecycleState)currentSettingsLifecycleState {
    return [self.editingAdapter lifecycleState];
}

- (void)synchronizeEditingStateWithMutationAvailability {
    if (![self currentListMutationsAllowed] && self.tableView.editing) {
        [self leaveEditingModeClearingSelectionAnimated:NO];
        [self updateToolbarVisibilityAnimated:NO];
        [self updateNavigationItemsForCurrentState];
    }
}

- (void)refreshSelectionPresentation {
    [self updateToolbarForCurrentState];
    [self updateNavigationItemsForCurrentState];
}

- (void)refreshEditingModePresentationAnimated:(BOOL)animated {
    [self refreshSelectionPresentation];
    [self updateInteractivePopGestureEnabled];
    [self updateToolbarVisibilityAnimated:animated];
}

- (void)presentEditingFailureMessage:(NSString *)message {
    [self presentFailureMessage:message];
}

- (void)goBack {
    if (self.tableView.editing) {
        [self leaveEditingModeClearingSelectionAnimated:NO];
    }
    [self updateInteractivePopGestureEnabled];
    [self updateToolbarVisibilityAnimated:NO];
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)self.state.visibleItemCount;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NTYTRuleListItem *item = [self.state itemAtVisibleIndex:(NSUInteger)indexPath.row];
    return item ? [self heightForRuleText:item.text] : 44.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NTYTSettingsCell *cell =
        [tableView dequeueReusableCellWithIdentifier:@"NTYTSettingsCell"
                                        forIndexPath:indexPath];
    NTYTRuleListItem *item = [self.state itemAtVisibleIndex:(NSUInteger)indexPath.row];
    [cell configureWithText:item.text ?: @""];
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NTYTRuleListItem *item = [self.state itemAtVisibleIndex:(NSUInteger)indexPath.row];
    if (tableView.editing) {
        if (item) {
            [self.state setIdentifier:item.identifier selected:YES];
        }
        [self refreshSelectionPresentation];
        return;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (item) {
        [self beginEditingRuleItem:item];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.editing) {
        NTYTRuleListItem *item = [self.state itemAtVisibleIndex:(NSUInteger)indexPath.row];
        if (item) {
            [self.state setIdentifier:item.identifier selected:NO];
        }
        [self refreshSelectionPresentation];
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return !self.state.isSearchActive && [self currentListMutationsAllowed];
}

- (void)tableView:(UITableView *)tableView
moveRowAtIndexPath:(NSIndexPath *)fromIndexPath
      toIndexPath:(NSIndexPath *)toIndexPath {
    NTYTRuleListItem *item = [self.state itemAtVisibleIndex:(NSUInteger)fromIndexPath.row];
    if (self.state.isSearchActive || !item || (NSUInteger)toIndexPath.row >= self.state.visibleItemCount) {
        [self reloadAuthoritativeStateAndRender];
        return;
    }
    [self requestMoveRuleItem:item toIndex:(NSUInteger)toIndexPath.row];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.editing || ![self currentListMutationsAllowed]) {
        return UITableViewCellEditingStyleNone;
    }
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle != UITableViewCellEditingStyleDelete) {
        return;
    }
    NTYTRuleListItem *item = [self.state itemAtVisibleIndex:(NSUInteger)indexPath.row];
    if (item) {
        [self requestDeleteRuleItem:item];
    }
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self.state updateSearchText:searchText];
    [self renderCurrentState];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:NO animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    searchBar.text = @"";
    [searchBar resignFirstResponder];
    [searchBar setShowsCancelButton:NO animated:YES];
    [self.state updateSearchText:@""];
    [self renderCurrentState];
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateBegan || self.tableView.editing) {
        return;
    }
    NSIndexPath *indexPath =
        [self.tableView indexPathForRowAtPoint:[gesture locationInView:self.tableView]];
    if (!indexPath) {
        return;
    }
    NTYTRuleListItem *item = [self.state itemAtVisibleIndex:(NSUInteger)indexPath.row];
    if (!item) {
        return;
    }
    UIPasteboard.generalPasteboard.string = item.text;
    [self presentCopyFeedbackForText:item.text];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return !self.tableView.editing;
}

@end
