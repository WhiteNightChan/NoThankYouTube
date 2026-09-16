#import "NTYTLVSearchHelper.h"
#import "NTYTLVPrivate.h"
#import "NTYTLVSelectHelper.h"
#import "UI/NTYTRuleListItem.h"

@implementation NTYTRuleListViewController (NTYTLVSearchHelper)

- (void)applySearchStateForText:(NSString *)searchText {
    NSString *trimmed = [searchText stringByTrimmingCharactersInSet:
        [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    self.searchText = trimmed;
    self.isSearching = trimmed.length > 0;
}

- (void)rebuildFilteredItemsForCurrentSearchText {
    [self.filteredItems removeAllObjects];
    if (!self.isSearching) {
        return;
    }
    for (NTYTRuleListItem *item in self.items) {
        if ([item.text rangeOfString:self.searchText
                             options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [self.filteredItems addObject:item];
        }
    }
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self clearEditingSelectionForSearchRefresh];
    [self applySearchStateForText:searchText];
    [self reloadListDataForCurrentState];
    [self refreshListUIForCurrentState];
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
    [self clearEditingSelectionForSearchRefresh];
    [self applySearchStateForText:@""];
    [self reloadListDataForCurrentState];
    [self refreshListUIForCurrentState];
}

@end
