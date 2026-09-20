#import "NTYTLVDeleteFlowHelper.h"
#import "NTYTLVPrivate.h"
#import "NTYTLVResolveHelper.h"
#import "NTYTLVSelectHelper.h"
#import "UI/NTYTListEditingAdapter.h"
#import "UI/NTYTRuleListItem.h"
#import "UI/NTYTUIStrings.h"
#import "Persistence/NTYTSettingsCoordinator.h"

@implementation NTYTRuleListViewController (NTYTLVDeleteFlowHelper)

- (NSArray<NSIndexPath *> *)selectedIndexPathsForDeleteAction {
    return [self.tableView.indexPathsForSelectedRows copy] ?: @[];
}

- (void)deleteSelectedItemsTapped {
    NSArray<NSIndexPath *> *selected = [self selectedIndexPathsForDeleteAction];
    if (selected.count == 0 || ![self.editingAdapter mutationsAllowed]) {
        return;
    }
    NSString *expression = nil;
    if (selected.count == 1) {
        expression = [self resolvedItemForIndexPath:selected.firstObject].text;
    }
    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:NTYTDeleteTitle(selected.count)
                                            message:NTYTDeleteMessage(selected.count, expression)
                                     preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Delete"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(__unused UIAlertAction *action) {
        [self performDeleteSelectedItems];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)performDeleteSelectedItems {
    NSArray<NSIndexPath *> *selected = [self selectedIndexPathsForDeleteAction];
    if (selected.count == 0) {
        return;
    }

    NSArray<NSUUID *> *identifiers =
        [self resolvedIdentifiersForIndexPaths:selected];

    if (identifiers.count != selected.count) {
        [self loadItemsFromAuthoritativeSource];
        [self clearEditingSelectionForSearchRefresh];
        [self reloadListDataForCurrentState];
        [self refreshListUIForCurrentState];
        [self presentFailureMessage:@"At least one selected rule no longer exists."];
        return;
    }

    NTYTMutationResult *result = [self.editingAdapter deleteIdentifiers:identifiers];
    [self loadItemsFromAuthoritativeSource];
    [self clearEditingSelectionForSearchRefresh];
    [self reloadListDataForCurrentState];
    [self refreshListUIForCurrentState];
    if (!result.isSuccess) {
        [self presentFailureMessage:result.message];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.editing || ![self.editingAdapter mutationsAllowed]) {
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
    NTYTRuleListItem *item = [self resolvedItemForIndexPath:indexPath];
    if (!item) {
        return;
    }
    NTYTMutationResult *result = [self.editingAdapter deleteIdentifier:item.identifier];
    [self loadItemsFromAuthoritativeSource];
    [self clearEditingSelectionForSearchRefresh];
    [self reloadListDataForCurrentState];
    [self refreshListUIForCurrentState];
    if (!result.isSuccess) {
        [self presentFailureMessage:result.message];
    }
}

@end
