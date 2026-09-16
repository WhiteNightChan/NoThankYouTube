#import "NTYTLVMeasureHelper.h"
#import "NTYTLVPrivate.h"
#import "NTYTLVTextCell.h"

@implementation NTYTRuleListViewController (NTYTLVMeasureHelper)

- (NTYTLVTextCell *)estimatedSizingCell {
    if (!self.sizingCell) {
        self.sizingCell = [[NTYTLVTextCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                reuseIdentifier:nil];
    }
    return self.sizingCell;
}

- (CGFloat)estimatedHeightForDisplayText:(NSString *)text tableView:(UITableView *)tableView {
    CGFloat width = CGRectGetWidth(tableView.bounds);
    if (width <= 0.0) {
        return 44.0;
    }
    NTYTLVTextCell *cell = [self estimatedSizingCell];
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

@end
