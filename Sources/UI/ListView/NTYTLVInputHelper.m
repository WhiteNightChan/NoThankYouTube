#import "NTYTLVInputHelper.h"
#import "NTYTLVPrivate.h"
#import "NTYTLVSelectHelper.h"
#import "UI/NTYTListEditingAdapter.h"
#import "UI/NTYTRuleListItem.h"
#import "Localization/NTYTUIStrings.h"
#import "Localization/NTYTErrorStrings.h"
#import "Persistence/NTYTSettingsCoordinator.h"

@implementation NTYTRuleListViewController (NTYTLVInputHelper)

- (UITextView *)configuredInputTextViewWithFrame:(CGRect)frame {
    UITextView *textView = [[UITextView alloc] initWithFrame:frame];
    textView.font = [UIFont systemFontOfSize:14.0];
    textView.textContainerInset = UIEdgeInsetsMake(8, 4, 8, 4);
    textView.returnKeyType = UIReturnKeyDone;
    textView.delegate = self;
    textView.autocorrectionType = UITextAutocorrectionTypeNo;
    textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textView.smartQuotesType = UITextSmartQuotesTypeNo;
    textView.smartDashesType = UITextSmartDashesTypeNo;
    textView.smartInsertDeleteType = UITextSmartInsertDeleteTypeNo;
    textView.textContainer.lineBreakMode = NSLineBreakByCharWrapping;
    textView.scrollEnabled = YES;
    textView.layer.borderWidth = 0.5;
    textView.layer.cornerRadius = 6.0;
    return textView;
}

- (UIAlertController *)inputAlertWithTitle:(NSString *)title
                                      draft:(NSString *)draft
                                 diagnostic:(NSString *)diagnostic
                                   textView:(UITextView **)textView {
    self.currentInputPlaceholder = NTYTInputPlaceholder();
    NSString *message = diagnostic.length > 0
        ? [NSString stringWithFormat:@"%@\n%@", diagnostic, NTYTInputMessage()]
        : NTYTInputMessage();
    NSString *spacer = @"\n\n\n\n\n\n\n\n\n\n";
    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:title
                                            message:[message stringByAppendingString:spacer]
                                     preferredStyle:UIAlertControllerStyleAlert];
    UIFont *font = [UIFont systemFontOfSize:14.0];
    UIFont *messageFont = [UIFont systemFontOfSize:13.0];

    NSDictionary *messageAttributes = @{
        NSFontAttributeName: messageFont
    };
    CGSize messageConstraint = CGSizeMake(238.0, CGFLOAT_MAX);

    CGRect baseMessageRect =
        [NTYTInputMessage() boundingRectWithSize:messageConstraint
                                        options:NSStringDrawingUsesLineFragmentOrigin |
                                                NSStringDrawingUsesFontLeading
                                     attributes:messageAttributes
                                        context:nil];

    CGRect actualMessageRect =
        [message boundingRectWithSize:messageConstraint
                              options:NSStringDrawingUsesLineFragmentOrigin |
                                      NSStringDrawingUsesFontLeading
                           attributes:messageAttributes
                              context:nil];

    CGFloat extraMessageHeight =
        MAX(0.0,
            ceil(CGRectGetHeight(actualMessageRect)) -
            ceil(CGRectGetHeight(baseMessageRect)));

    CGFloat inputY = 70.0 + extraMessageHeight;

    UITextView *input =
        [self configuredInputTextViewWithFrame:CGRectMake(
            10,
            inputY,
            250,
            font.lineHeight * 9 + 12)];
    
    if (draft != nil) {
        input.text = draft;
        input.textColor = UIColor.labelColor;
    } else {
        input.text = self.currentInputPlaceholder;
        input.textColor = UIColor.secondaryLabelColor;
    }
    [alert.view addSubview:input];
    if (textView) {
        *textView = input;
    }
    return alert;
}

- (NSString *)rawDraftFromTextView:(UITextView *)textView {
    BOOL placeholder = [textView.textColor isEqual:UIColor.secondaryLabelColor] &&
        [textView.text isEqualToString:self.currentInputPlaceholder];
    return placeholder ? @"" : (textView.text ?: @"");
}

- (void)reloadAfterSuccessfulMutation {
    [self loadItemsFromAuthoritativeSource];
    [self clearEditingSelectionForSearchRefresh];
    [self reloadListDataForCurrentState];
    [self refreshListUIForCurrentState];
}

- (void)presentAddInputAlertWithDraft:(NSString *)draft diagnostic:(NSString *)diagnostic {
    UITextView *textView = nil;
    UIAlertController *alert = [self inputAlertWithTitle:NTYTAddTitle()
                                                  draft:draft
                                             diagnostic:diagnostic
                                               textView:&textView];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:NTYTSaveTitle()
                                              style:UIAlertActionStyleDefault
                                            handler:^(__unused UIAlertAction *action) {
        typeof(self) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        NSString *rawDraft = [strongSelf rawDraftFromTextView:textView];
        NTYTMutationResult *result = [strongSelf.editingAdapter addRawExpression:rawDraft];
        if (result.isSuccess) {
            [strongSelf reloadAfterSuccessfulMutation];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf presentAddInputAlertWithDraft:rawDraft
                                              diagnostic:NTYTMutationErrorText(result)];
            });
        }
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:NTYTCancelTitle()
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)presentEditInputAlertForItem:(NTYTRuleListItem *)item
                               draft:(NSString *)draft
                          diagnostic:(NSString *)diagnostic {
    UITextView *textView = nil;
    UIAlertController *alert = [self inputAlertWithTitle:NTYTEditTitle()
                                                  draft:draft
                                             diagnostic:diagnostic
                                               textView:&textView];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:NTYTSaveTitle()
                                              style:UIAlertActionStyleDefault
                                            handler:^(__unused UIAlertAction *action) {
        typeof(self) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        NSString *rawDraft = [strongSelf rawDraftFromTextView:textView];
        NTYTMutationResult *result =
            [strongSelf.editingAdapter editIdentifier:item.identifier rawExpression:rawDraft];
        if (result.isSuccess) {
            [strongSelf reloadAfterSuccessfulMutation];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf presentEditInputAlertForItem:item
                                                   draft:rawDraft
                                              diagnostic:NTYTMutationErrorText(result)];
            });
        }
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:NTYTCancelTitle()
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (BOOL)textView:(UITextView *)textView
shouldChangeTextInRange:(NSRange)range
 replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if ([textView.textColor isEqual:UIColor.secondaryLabelColor] &&
        [textView.text isEqualToString:self.currentInputPlaceholder]) {
        textView.text = @"";
        textView.textColor = UIColor.labelColor;
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (textView.text.length == 0 && self.currentInputPlaceholder.length > 0) {
        textView.text = self.currentInputPlaceholder;
        textView.textColor = UIColor.secondaryLabelColor;
    }
}

@end
