#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NTYTContentType) {
    NTYTContentTypeVideo = 1,
};

typedef NS_ENUM(NSInteger, NTYTMatchResult) {
    NTYTMatchResultNoMatch = 0,
    NTYTMatchResultMatch = 1,
    NTYTMatchResultUnavailable = 2,
};

typedef NS_ENUM(NSInteger, NTYTDecision) {
    NTYTDecisionNoMatch = 0,
    NTYTDecisionAllow = 1,
    NTYTDecisionBlock = 2,
};

typedef NS_ENUM(NSInteger, NTYTListID) {
    NTYTListIDGeneralBlock = 0,
    NTYTListIDGeneralAllow,
    NTYTListIDVideosTitle,
    NTYTListIDVideosChannel,
    NTYTListIDVideosID,
    NTYTListIDChannelsBlock,
    NTYTListIDChannelsAllow,
};

typedef NS_ENUM(NSInteger, NTYTListKind) {
    NTYTListKindBlock = 0,
    NTYTListKindAllow = 1,
};

typedef NS_ENUM(NSInteger, NTYTTargetKind) {
    NTYTTargetKindTitle = 0,
    NTYTTargetKindChannel = 1,
    NTYTTargetKindVideoID = 2,
};

typedef NS_ENUM(NSInteger, NTYTListOptionID) {
    NTYTListOptionIDCaseSensitive = 0,
    NTYTListOptionIDExactMatch = 1,
};

typedef NS_ENUM(NSInteger, NTYTMatcherKind) {
    NTYTMatcherKindPlain = 0,
    NTYTMatcherKindRegex = 1,
};

typedef NS_ENUM(NSInteger, NTYTModifierKind) {
    NTYTModifierKindChannel = 0,
    NTYTModifierKindContent = 1,
    NTYTModifierKindVideo = 2,
};

typedef NS_ENUM(NSInteger, NTYTSettingsLifecycleState) {
    NTYTSettingsLifecycleStateAbsent = 0,
    NTYTSettingsLifecycleStateSupportedValid = 1,
    NTYTSettingsLifecycleStateSupportedDegraded = 2,
    NTYTSettingsLifecycleStateUnusable = 3,
};

typedef NS_ENUM(NSInteger, NTYTMutationErrorCode) {
    NTYTMutationErrorNone = 0,
    NTYTMutationErrorInvalidExpression,
    NTYTMutationErrorDuplicateExpression,
    NTYTMutationErrorRuleNotFound,
    NTYTMutationErrorInvalidRequest,
    NTYTMutationErrorMutationProtected,
    NTYTMutationErrorSnapshotBuild,
    NTYTMutationErrorPersistence,
};

FOUNDATION_EXPORT NTYTMatchResult NTYTNegateMatchResult(NTYTMatchResult result);
FOUNDATION_EXPORT NSString *NTYTSettingsLifecycleDescription(NTYTSettingsLifecycleState state);

NS_ASSUME_NONNULL_END
