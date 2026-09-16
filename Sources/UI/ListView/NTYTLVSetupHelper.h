#import "NTYTRuleListViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface NTYTRuleListViewController (NTYTLVSetupHelper)
- (void)configureTableViewAppearance;
- (UISearchBar *)configuredSearchBar;
- (void)configureLongPressGesture;
- (UIBarButtonItem *)fixedSpaceBarButtonItemWithWidth:(CGFloat)width;
- (UIBarButtonItem *)backBarButtonItem;
- (UIBarButtonItem *)textBarButtonItemWithTitle:(NSString *)title
                                      textColor:(UIColor *)textColor
                                     fontWeight:(UIFontWeight)fontWeight
                                         target:(nullable id)target
                                         action:(nullable SEL)action;
- (UIBarButtonItem *)addBarButtonItem;
- (UIBarButtonItem *)editBarButtonItemForEditing:(BOOL)editing;
- (void)configureToolbarItems;
@end

NS_ASSUME_NONNULL_END