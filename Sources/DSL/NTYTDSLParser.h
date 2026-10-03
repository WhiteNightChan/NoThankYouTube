#import <Foundation/Foundation.h>

@class NTYTRuntimeRule;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSErrorDomain const NTYTDSLErrorDomain;

typedef NS_ERROR_ENUM(NTYTDSLErrorDomain, NTYTDSLErrorCode) {
    NTYTDSLErrorEmptyExpression = 1,
    NTYTDSLErrorNewline,
    NTYTDSLErrorMalformedModifier,
    NTYTDSLErrorUnknownModifier,
    NTYTDSLErrorMissingModifierValue,
    NTYTDSLErrorUnexpectedModifierValue,
    NTYTDSLErrorMissingSeparator,
    NTYTDSLErrorMissingMainMatcher,
    NTYTDSLErrorModifierAfterMain,
    NTYTDSLErrorMalformedEscape,
    NTYTDSLErrorMalformedRegex,
    NTYTDSLErrorEmptyRegex,
    NTYTDSLErrorUnsupportedRegexFlag,
    NTYTDSLErrorDuplicateRegexFlag,
    NTYTDSLErrorRegexCompile,
};

typedef NS_ENUM(NSInteger, NTYTDSLErrorReason) {
    NTYTDSLErrorReasonInvalidInput = 0,
    NTYTDSLErrorReasonContainsNewline,
    NTYTDSLErrorReasonEmptyExpression,
    NTYTDSLErrorReasonMissingMainMatcherAfterModifiers,
    NTYTDSLErrorReasonMissingSeparatorAfterModifier,
    NTYTDSLErrorReasonMalformedModifierName,
    NTYTDSLErrorReasonUnknownModifier,
    NTYTDSLErrorReasonPredicateModifierValueNotAllowed,
    NTYTDSLErrorReasonModifierValueRequired,
    NTYTDSLErrorReasonModifierValueMissing,
    NTYTDSLErrorReasonModifierValueEmpty,
    NTYTDSLErrorReasonDetachedNegativeMarker,
    NTYTDSLErrorReasonRegexModifierMissingClosingBrace,
    NTYTDSLErrorReasonModifierMissingClosingBrace,
    NTYTDSLErrorReasonMatcherRequired,
    NTYTDSLErrorReasonModifierAfterMain,
    NTYTDSLErrorReasonMalformedRegexLiteral,
    NTYTDSLErrorReasonRegexIncompleteEscape,
    NTYTDSLErrorReasonRegexMissingClosingDelimiter,
    NTYTDSLErrorReasonEmptyRegex,
    NTYTDSLErrorReasonUnsupportedRegexFlag,
    NTYTDSLErrorReasonDuplicateRegexFlag,
    NTYTDSLErrorReasonRegexCompileFailed,
    NTYTDSLErrorReasonPlainMatcherIncompleteEscape,
};

FOUNDATION_EXPORT NSErrorUserInfoKey const NTYTDSLErrorReasonKey;
FOUNDATION_EXPORT NSErrorUserInfoKey const NTYTDSLErrorModifierNameKey;
FOUNDATION_EXPORT NSErrorUserInfoKey const NTYTDSLErrorRegexFlagKey;

@interface NTYTDSLParser : NSObject

+ (nullable NTYTRuntimeRule *)parseExpression:(NSString *)rawExpression
                                    identifier:(NSUUID *)identifier
                                         error:(NSError * _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
