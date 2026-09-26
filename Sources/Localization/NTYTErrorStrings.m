#import "NTYTErrorStrings.h"

#import "NTYTLocalization.h"
#import "DSL/NTYTDSLParser.h"
#import "Persistence/NTYTSettingsCoordinator.h"
#import "Persistence/NTYTSettingsTransferService.h"

static NSString * _Nullable NTYTDSLErrorText(NSError *error) {
    if (![error.domain isEqualToString:NTYTDSLErrorDomain]) {
        return nil;
    }
    NSNumber *reasonValue = error.userInfo[NTYTDSLErrorReasonKey];
    if (![reasonValue isKindOfClass:NSNumber.class]) {
        return nil;
    }
    NSString *key = nil;
    switch ((NTYTDSLErrorReason)reasonValue.integerValue) {
        case NTYTDSLErrorReasonInvalidInput: key = @"error.dsl.generic"; break;
        case NTYTDSLErrorReasonContainsNewline: key = @"error.dsl.contains_newline"; break;
        case NTYTDSLErrorReasonEmptyExpression: key = @"error.dsl.empty_expression"; break;
        case NTYTDSLErrorReasonMissingMainMatcherAfterModifiers: key = @"error.dsl.missing_main_matcher_after_modifiers"; break;
        case NTYTDSLErrorReasonMissingSeparatorAfterModifier: key = @"error.dsl.missing_separator_after_modifier"; break;
        case NTYTDSLErrorReasonMalformedModifierName: key = @"error.dsl.malformed_modifier_name"; break;
        case NTYTDSLErrorReasonUnknownModifier: {
            NSString *name = error.userInfo[NTYTDSLErrorModifierNameKey];
            if (![name isKindOfClass:NSString.class]) return nil;
            return [NSString stringWithFormat:NTYTLocalizedString(@"error.dsl.unknown_modifier"), name];
        }
        case NTYTDSLErrorReasonPredicateModifierValueNotAllowed: key = @"error.dsl.predicate_modifier_value_not_allowed"; break;
        case NTYTDSLErrorReasonModifierValueRequired: key = @"error.dsl.modifier_value_required"; break;
        case NTYTDSLErrorReasonModifierValueMissing: key = @"error.dsl.modifier_value_missing"; break;
        case NTYTDSLErrorReasonModifierValueEmpty: key = @"error.dsl.modifier_value_empty"; break;
        case NTYTDSLErrorReasonDetachedNegativeMarker: key = @"error.dsl.detached_negative_marker"; break;
        case NTYTDSLErrorReasonRegexModifierMissingClosingBrace: key = @"error.dsl.regex_modifier_missing_closing_brace"; break;
        case NTYTDSLErrorReasonModifierMissingClosingBrace: key = @"error.dsl.modifier_missing_closing_brace"; break;
        case NTYTDSLErrorReasonMatcherRequired: key = @"error.dsl.matcher_required"; break;
        case NTYTDSLErrorReasonModifierAfterMain: key = @"error.dsl.modifier_after_main"; break;
        case NTYTDSLErrorReasonMalformedRegexLiteral: key = @"error.dsl.malformed_regex_literal"; break;
        case NTYTDSLErrorReasonRegexIncompleteEscape: key = @"error.dsl.regex_incomplete_escape"; break;
        case NTYTDSLErrorReasonRegexMissingClosingDelimiter: key = @"error.dsl.regex_missing_closing_delimiter"; break;
        case NTYTDSLErrorReasonEmptyRegex: key = @"error.dsl.empty_regex"; break;
        case NTYTDSLErrorReasonUnsupportedRegexFlag: {
            NSString *flag = error.userInfo[NTYTDSLErrorRegexFlagKey];
            if (![flag isKindOfClass:NSString.class]) return nil;
            return [NSString stringWithFormat:NTYTLocalizedString(@"error.dsl.unsupported_regex_flag"), flag];
        }
        case NTYTDSLErrorReasonDuplicateRegexFlag: key = @"error.dsl.duplicate_regex_flag"; break;
        case NTYTDSLErrorReasonRegexCompileFailed: key = @"error.dsl.regex_compile_failed"; break;
        case NTYTDSLErrorReasonPlainMatcherIncompleteEscape: key = @"error.dsl.plain_matcher_incomplete_escape"; break;
    }
    return key ? NTYTLocalizedString(key) : nil;
}

NSString *NTYTMutationErrorText(NTYTMutationResult *result) {
    switch (result.failureReason) {
        case NTYTMutationFailureReasonNone: break;
        case NTYTMutationFailureReasonExpressionNotText: return NTYTLocalizedString(@"error.mutation.expression_not_text");
        case NTYTMutationFailureReasonDSLParseFailed:
            return NTYTDSLErrorText(result.underlyingError)
                ?: NTYTLocalizedString(@"error.mutation.invalid_expression");
        case NTYTMutationFailureReasonDuplicateExpression: return NTYTLocalizedString(@"error.mutation.duplicate_expression");
        case NTYTMutationFailureReasonRuleNotFound: return NTYTLocalizedString(@"error.mutation.rule_not_found");
        case NTYTMutationFailureReasonSelectedRuleMissing: return NTYTLocalizedString(@"error.mutation.selected_rule_missing");
        case NTYTMutationFailureReasonInvalidList: return NTYTLocalizedString(@"error.mutation.invalid_list");
        case NTYTMutationFailureReasonNoRulesSelected: return NTYTLocalizedString(@"error.mutation.no_rules_selected");
        case NTYTMutationFailureReasonDuplicateRuleIdentifiers: return NTYTLocalizedString(@"error.mutation.duplicate_rule_identifiers");
        case NTYTMutationFailureReasonInvalidDestinationPosition: return NTYTLocalizedString(@"error.mutation.invalid_destination_position");
        case NTYTMutationFailureReasonUnsupportedOption: return NTYTLocalizedString(@"error.mutation.unsupported_option");
        case NTYTMutationFailureReasonMutationProtected: return NTYTLocalizedString(@"error.mutation.mutation_protected");
        case NTYTMutationFailureReasonSnapshotBuildFailed: return NTYTLocalizedString(@"error.mutation.snapshot_build_failed");
        case NTYTMutationFailureReasonPersistenceFailed: return NTYTLocalizedString(@"error.mutation.persistence_failed");
    }
    if (result.errorCode == NTYTMutationErrorInvalidExpression) {
        return NTYTLocalizedString(@"error.mutation.invalid_expression");
    }
    if (result.errorCode == NTYTMutationErrorInvalidRequest) {
        return NTYTLocalizedString(@"error.mutation.invalid_request");
    }
    return NTYTLocalizedString(@"error.mutation.generic");
}

NSString *NTYTSettingsTransferErrorText(NSError *error) {
    if ([error.domain isEqualToString:NTYTSettingsTransferErrorDomain]) {
        switch ((NTYTSettingsTransferErrorCode)error.code) {
            case NTYTSettingsTransferErrorRead: return NTYTLocalizedString(@"error.transfer.read");
            case NTYTSettingsTransferErrorInvalidFile: return NTYTLocalizedString(@"error.transfer.invalid_file");
            case NTYTSettingsTransferErrorUnsupportedVersion: return NTYTLocalizedString(@"error.transfer.unsupported_version");
            case NTYTSettingsTransferErrorValidation: return NTYTLocalizedString(@"error.transfer.validation");
            case NTYTSettingsTransferErrorExportCreation: return NTYTLocalizedString(@"error.transfer.export_creation");
        }
    }
    return NTYTLocalizedString(@"error.transfer.generic");
}

NSString *NTYTImportCommitErrorText(NTYTImportCommitResult *result) {
    (void)result;
    return NTYTLocalizedString(@"error.transfer.import_commit_failed");
}
