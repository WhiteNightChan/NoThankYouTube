#import "NTYTRuleListViewController.h"

@class NTYTRuleListItem;

@interface NTYTRuleListViewController (NTYTLVInputHelper)
- (UITextView *)configuredInputTextViewWithFrame:(CGRect)frame;
- (void)presentAddInputAlertWithDraft:(nullable NSString *)draft
                           diagnostic:(nullable NSString *)diagnostic;
- (void)presentEditInputAlertForItem:(NTYTRuleListItem *)item
                               draft:(NSString *)draft
                          diagnostic:(nullable NSString *)diagnostic;
@end
