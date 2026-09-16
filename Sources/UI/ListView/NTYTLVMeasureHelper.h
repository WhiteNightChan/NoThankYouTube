#import "NTYTRuleListViewController.h"

@class NTYTLVTextCell;

@interface NTYTRuleListViewController (NTYTLVMeasureHelper)
- (NTYTLVTextCell *)estimatedSizingCell;
- (CGFloat)estimatedHeightForDisplayText:(NSString *)text tableView:(UITableView *)tableView;
@end
