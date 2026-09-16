#import "NTYTRuleListViewController.h"

@interface NTYTRuleListViewController (NTYTLVDeleteFlowHelper)
- (NSArray<NSIndexPath *> *)selectedIndexPathsForDeleteAction;
- (void)deleteSelectedItemsTapped;
- (void)performDeleteSelectedItems;
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath;
@end
