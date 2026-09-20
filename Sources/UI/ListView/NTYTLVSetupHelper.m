#import "NTYTLVSetupHelper.h"
#import "NTYTLVDeleteFlowHelper.h"
#import "NTYTLVPrivate.h"
#import "NTYTLVSelectHelper.h"
#import "UI/NTYTUIStrings.h"

@implementation NTYTRuleListViewController (NTYTLVSetupHelper)

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
    return [self textBarButtonItemWithTitle:(editing ? @"Done" : @"Edit")
                                  textColor:UIColor.labelColor
                                 fontWeight:UIFontWeightRegular
                                     target:self
                                     action:@selector(editButtonTapped)];
}

- (void)configureToolbarItems {
    UIBarButtonItem *selectAll = [[UIBarButtonItem alloc] initWithTitle:@"Select All"
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(selectAllToolbarButtonTapped)];
    selectAll.tintColor = UIColor.systemBlueColor;

    UIBarButtonItem *space =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                     target:nil
                                                     action:nil];
    UIBarButtonItem *deleteButton = [[UIBarButtonItem alloc] initWithTitle:@"Delete"
                                                                      style:UIBarButtonItemStylePlain
                                                                     target:self
                                                                     action:@selector(deleteSelectedItemsTapped)];
    deleteButton.tintColor = UIColor.systemRedColor;
    selectAll.enabled = NO;
    deleteButton.enabled = NO;
    self.toolbarItems = @[selectAll, space, deleteButton];
}

@end
