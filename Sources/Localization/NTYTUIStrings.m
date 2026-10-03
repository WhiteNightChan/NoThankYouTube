#import "NTYTUIStrings.h"

#import "NTYTLocalization.h"

NSString *NTYTAppName(void) { return @"NoThankYouTube"; }

NSString *NTYTListTitle(NTYTListID listID) {
    switch (listID) {
        case NTYTListIDGeneralBlock:
        case NTYTListIDChannelsBlock:
        case NTYTListIDGlobalBlock:
            return NTYTLocalizedString(@"ui.list.block");
        case NTYTListIDGeneralAllow:
        case NTYTListIDChannelsAllow:
        case NTYTListIDGlobalAllow:
            return NTYTLocalizedString(@"ui.list.allow");
        case NTYTListIDVideosTitle:
        case NTYTListIDPlaylistTitle:
            return NTYTLocalizedString(@"ui.list.title");
        case NTYTListIDVideosChannel:
        case NTYTListIDPostChannel:
        case NTYTListIDPlaylistChannel:
            return NTYTLocalizedString(@"ui.list.channel");
        case NTYTListIDVideosID:
            return NTYTLocalizedString(@"ui.list.video_id");
        case NTYTListIDPostContent:
            return NTYTLocalizedString(@"ui.list.content");
        case NTYTListIDPlaylistID:
            return NTYTLocalizedString(@"ui.list.playlist_id");
    }
    return NTYTLocalizedString(@"ui.list.rules");
}

NSString *NTYTCategoryTitle(NSUInteger categoryIndex) {
    switch (categoryIndex) {
        case 0: return NTYTLocalizedString(@"ui.category.general");
        case 1: return NTYTLocalizedString(@"ui.category.video");
        case 2: return NTYTLocalizedString(@"ui.category.channel");
        case 3: return NTYTLocalizedString(@"ui.category.post");
        case 4: return NTYTLocalizedString(@"ui.category.playlist");
        case 5: return NTYTLocalizedString(@"ui.category.global");
    }
    return NTYTAppName();
}

NSString *NTYTOptionTitle(NTYTListOptionID optionID) {
    switch (optionID) {
        case NTYTListOptionIDCaseSensitive: return NTYTLocalizedString(@"ui.option.case_sensitive");
        case NTYTListOptionIDExactMatch: return NTYTLocalizedString(@"ui.option.exact_match");
    }
    return NTYTLocalizedString(@"ui.option.generic");
}

NSString *NTYTSettingsLifecycleText(NTYTSettingsLifecycleState state) {
    switch (state) {
        case NTYTSettingsLifecycleStateAbsent: return NTYTLocalizedString(@"ui.lifecycle.absent");
        case NTYTSettingsLifecycleStateSupportedValid: return NTYTLocalizedString(@"ui.lifecycle.supported_valid");
        case NTYTSettingsLifecycleStateSupportedDegraded: return NTYTLocalizedString(@"ui.lifecycle.supported_degraded");
        case NTYTSettingsLifecycleStateUnusable: return NTYTLocalizedString(@"ui.lifecycle.unusable");
    }
    return NTYTLocalizedString(@"ui.lifecycle.unknown");
}

NSString *NTYTReadOnlyText(NTYTSettingsLifecycleState state) {
    return [NSString stringWithFormat:NTYTLocalizedString(@"ui.status.read_only_format"),
                                      NTYTSettingsLifecycleText(state)];
}

NSString *NTYTOKTitle(void) { return NTYTLocalizedString(@"ui.common.action.ok"); }
NSString *NTYTSaveTitle(void) { return NTYTLocalizedString(@"ui.common.action.save"); }
NSString *NTYTCancelTitle(void) { return NTYTLocalizedString(@"ui.common.action.cancel"); }
NSString *NTYTDeleteActionTitle(void) { return NTYTLocalizedString(@"ui.common.action.delete"); }
NSString *NTYTEditActionTitle(void) { return NTYTLocalizedString(@"ui.common.action.edit"); }
NSString *NTYTDoneTitle(void) { return NTYTLocalizedString(@"ui.common.action.done"); }
NSString *NTYTSelectAllTitle(void) { return NTYTLocalizedString(@"ui.common.action.select_all"); }
NSString *NTYTDeselectAllTitle(void) { return NTYTLocalizedString(@"ui.common.action.deselect_all"); }
NSString *NTYTHideMixTitle(void) { return NTYTLocalizedString(@"ui.option.hide_mix"); }

NSString *NTYTAddTitle(void) { return NTYTLocalizedString(@"ui.rule.editor.add_title"); }
NSString *NTYTEditTitle(void) { return NTYTLocalizedString(@"ui.rule.editor.edit_title"); }
NSString *NTYTSearchPlaceholder(void) { return NTYTLocalizedString(@"ui.rule.list.search_placeholder"); }
NSString *NTYTInputMessage(void) { return NTYTLocalizedString(@"ui.rule.editor.instruction"); }
NSString *NTYTInputPlaceholder(void) { return NTYTLocalizedString(@"ui.rule.editor.expression_placeholder"); }
NSString *NTYTEmptyListText(void) { return NTYTLocalizedString(@"ui.rule.list.empty"); }
NSString *NTYTNoResultsText(void) { return NTYTLocalizedString(@"ui.rule.list.empty_search"); }
NSString *NTYTSelectionStaleText(void) { return NTYTLocalizedString(@"ui.rule.delete.selection_stale"); }

NSString *NTYTDeleteTitle(NSUInteger count) {
    if (count == 1) return NTYTLocalizedString(@"ui.rule.delete.confirm_title_single");
    return [NSString stringWithFormat:NTYTLocalizedString(@"ui.rule.delete.confirm_title_multiple_format"),
                                      (unsigned long)count];
}

NSString *NTYTDeleteMessage(NSUInteger count, NSString *expression) {
    if (count == 1 && expression.length > 0) return expression;
    return NTYTLocalizedString(@"ui.rule.delete.confirm_message");
}

NSString *NTYTRuleCountText(NSUInteger count) {
    NSString *key = count == 1 ? @"ui.rule.list.count_single_format" : @"ui.rule.list.count_multiple_format";
    return [NSString stringWithFormat:NTYTLocalizedString(key), (unsigned long)count];
}

NSString *NTYTCopiedRuleText(NSString *expression) {
    return [NSString stringWithFormat:NTYTLocalizedString(@"ui.rule.list.copied_format"), expression];
}

NSString *NTYTImportSettingsTitle(void) { return NTYTLocalizedString(@"ui.transfer.import.title"); }
NSString *NTYTExportSettingsTitle(void) { return NTYTLocalizedString(@"ui.transfer.export.title"); }
NSString *NTYTImportSuccessText(void) { return NTYTLocalizedString(@"ui.transfer.import.success"); }
NSString *NTYTImportNoChangesText(void) { return NTYTLocalizedString(@"ui.transfer.import.no_changes"); }
NSString *NTYTImportReplaceTitle(void) { return NTYTLocalizedString(@"ui.transfer.import.replace_title"); }
NSString *NTYTImportReplaceMessage(void) { return NTYTLocalizedString(@"ui.transfer.import.replace_message"); }
NSString *NTYTImportReplaceActionTitle(void) { return NTYTLocalizedString(@"ui.transfer.import.action.replace"); }
NSString *NTYTImportPickerUnavailableText(void) { return NTYTLocalizedString(@"ui.transfer.import.picker_unavailable"); }
NSString *NTYTImportInvalidSelectionText(void) { return NTYTLocalizedString(@"ui.transfer.import.invalid_selection"); }
NSString *NTYTImportConfirmationUnavailableText(void) { return NTYTLocalizedString(@"ui.transfer.import.confirmation_unavailable"); }
NSString *NTYTExportSuccessText(void) { return NTYTLocalizedString(@"ui.transfer.export.success"); }
NSString *NTYTExportUnavailableText(void) { return NTYTLocalizedString(@"ui.transfer.export.unavailable"); }
NSString *NTYTExportSalvageNoticeText(void) { return NTYTLocalizedString(@"ui.transfer.export.salvage_notice"); }
NSString *NTYTExportPickerUnavailableText(void) { return NTYTLocalizedString(@"ui.transfer.export.picker_unavailable"); }
