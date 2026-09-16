#import "NTYTLVSelectHelper.h"
#import "UI/NTYTListEditingAdapter.h"
#import "NTYTLVDeleteFlowHelper.h"
#import "NTYTLVPresentHelper.h"
#import "NTYTLVPrivate.h"

@implementation NTYTRuleListViewController (NTYTLVSelectHelper)

- (NSInteger)currentSelectedCount {
    return self.tableView.editing ? [self selectedIndexPathsForDeleteAction].count : 0;
}

- (void)clearEditingSelectionForSearchRefresh {
    if (!self.tableView.editing) {
        return;
    }
    for (NSIndexPath *indexPath in [self.tableView.indexPathsForSelectedRows copy]) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

- (NSInteger)selectableRowCount {
    return self.isSearching ? self.filteredItems.count : self.items.count;
}

- (void)updateSelectionToolbarButtonsForCurrentState {
    if (self.toolbarItems.count < 3) {
        return;
    }
    NSInteger total = [self selectableRowCount];
    NSInteger selected = [self selectedIndexPathsForDeleteAction].count;
    UIBarButtonItem *selectAll = self.toolbarItems[0];
    UIBarButtonItem *deleteButton = self.toolbarItems[2];
    BOOL mutable = [self.editingAdapter mutationsAllowed];
    selectAll.enabled = mutable && self.tableView.editing && total > 0;
    deleteButton.enabled = mutable && selected > 0;
    selectAll.title = (total > 0 && selected == total) ? @"Deselect All" : @"Select All";
    [self updateRightBarButtonItemsForCurrentState];
}

- (void)selectAllToolbarButtonTapped {
    if (!self.tableView.editing || ![self.editingAdapter mutationsAllowed]) {
        return;
    }
    NSInteger total = [self selectableRowCount];
    NSInteger selected = [self selectedIndexPathsForDeleteAction].count;
    if (total > 0 && selected == total) {
        for (NSIndexPath *indexPath in [self.tableView.indexPathsForSelectedRows copy]) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
        }
    } else {
        for (NSInteger row = 0; row < total; row++) {
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]
                                        animated:NO
                                  scrollPosition:UITableViewScrollPositionNone];
        }
    }
    [self updateSelectionUIForCurrentState];
}

@end
