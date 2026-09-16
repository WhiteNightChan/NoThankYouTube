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

@interface NTYTDSLParser : NSObject

+ (nullable NTYTRuntimeRule *)parseExpression:(NSString *)rawExpression
                                    identifier:(NSUUID *)identifier
                                         error:(NSError * _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
