#import "NTYTRuleListVCEditing.h"

#import "NTYTRuleListVCInternal.h"
#import "NTYTRuleListItem.h"
#import "NTYTRuleListState.h"
#import "UI/NTYTListEditingAdapter.h"

#import "Localization/NTYTUIStrings.h"
#import "Localization/NTYTErrorStrings.h"
// Existing mutation result declarations; all requests use the editing Adapter.
#import "Persistence/NTYTSettingsCoordinator.h"

@implementation NTYTRuleListViewController (Editing)

- (void)addButtonTapped {
    if ([self currentListMutationsAllowed]) {
        [self presentAddInputAlertWithDraft:nil diagnostic:nil];
    }
}

- (void)editButtonTapped {
    if (![self currentListMutationsAllowed]) {
        return;
    }
    BOOL editing = !self.tableView.editing;
    if (editing) {
        [self.searchBar resignFirstResponder];
    }
    if (editing) {
        [self.state clearSelection];
        [self applySelectionProjectionToTableView];
        [self.tableView setEditing:YES animated:YES];
    } else {
        [self leaveEditingModeClearingSelectionAnimated:YES];
    }
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
    if (!editing && !self.tableView.editing) {
        [self.tableView beginUpdates];
        [self.tableView endUpdates];
    }
    [self refreshEditingModePresentationAnimated:YES];
}

- (void)leaveEditingModeClearingSelectionAnimated:(BOOL)animated {
    [self.state clearSelection];
    [self applySelectionProjectionToTableView];
    [self.tableView setEditing:NO animated:animated];
}

- (void)selectAllButtonTapped {
    if (!self.tableView.editing || ![self currentListMutationsAllowed]) {
        return;
    }
    if (self.state.areAllVisibleItemsSelected) {
        [self.state clearSelection];
    } else {
        [self.state selectAllVisibleItems];
    }
    [self applySelectionProjectionToTableView];
    [self refreshSelectionPresentation];
}

- (void)beginEditingRuleItem:(NTYTRuleListItem *)item {
    if ([self currentListMutationsAllowed]) {
        [self presentEditInputAlertForItem:item draft:item.text diagnostic:nil];
    }
}

- (void)requestDeleteRuleItem:(NTYTRuleListItem *)item {
    NTYTMutationResult *result = [self.editingAdapter deleteIdentifier:item.identifier];
    [self.state clearSelection];
    [self reloadAuthoritativeStateAndRender];
    if (!result.isSuccess) {
        [self presentEditingFailureMessage:NTYTMutationErrorText(result)];
    }
}

- (void)requestMoveRuleItem:(NTYTRuleListItem *)item toIndex:(NSUInteger)destinationIndex {
    NSUInteger sourceIndex = NSNotFound;
    for (NSUInteger index = 0; index < self.state.visibleItemCount; index++) {
        NTYTRuleListItem *visibleItem = [self.state itemAtVisibleIndex:index];
        if ([visibleItem.identifier isEqual:item.identifier]) {
            sourceIndex = index;
            break;
        }
    }
    if (![self.state moveVisibleItemFromIndex:sourceIndex toIndex:destinationIndex]) {
        [self reloadAuthoritativeStateAndRender];
        return;
    }

    NTYTMutationResult *result =
        [self.editingAdapter moveIdentifier:item.identifier toIndex:destinationIndex];
    // Move preserves logical selection for success, no-op, and failure alike.
    [self reloadAuthoritativeStateAndRender];
    if (!result.isSuccess) {
        [self presentEditingFailureMessage:NTYTMutationErrorText(result)];
    }
}

- (void)deleteSelectedItemsTapped {
    NSArray<NSUUID *> *selected = (self.tableView.editing ? [self.state selectedIdentifiersInVisibleOrder] : @[]);
    if (selected.count == 0 || ![self currentListMutationsAllowed]) {
        return;
    }

    NSString *expression = nil;
    if (selected.count == 1) {
        expression = [self.state itemWithIdentifier:selected.firstObject].text;
    }

    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:NTYTDeleteTitle(selected.count)
                                            message:NTYTDeleteMessage(selected.count, expression)
                                     preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NTYTDeleteActionTitle()
                                              style:UIAlertActionStyleDestructive
                                            handler:^(__unused UIAlertAction *action) {
        [self performDeleteSelectedItems];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:NTYTCancelTitle()
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)performDeleteSelectedItems {
    NSInteger selectedCount = (self.tableView.editing ? self.state.selectedCount : 0);
    if (selectedCount == 0) {
        return;
    }

    NSArray<NSUUID *> *identifiers = [self.state selectedIdentifiersInVisibleOrder];
    if (identifiers.count != selectedCount) {
        [self.state clearSelection];
        [self reloadAuthoritativeStateAndRender];
        [self presentEditingFailureMessage:NTYTSelectionStaleText()];
        return;
    }

    NTYTMutationResult *result = [self.editingAdapter deleteIdentifiers:identifiers];
    [self.state clearSelection];
    [self reloadAuthoritativeStateAndRender];
    if (!result.isSuccess) {
        [self presentEditingFailureMessage:NTYTMutationErrorText(result)];
    }
}

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
            [strongSelf.state clearSelection];
            [strongSelf reloadAuthoritativeStateAndRender];
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
            [strongSelf.state clearSelection];
            [strongSelf reloadAuthoritativeStateAndRender];
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
