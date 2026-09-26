#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NTYTContentType) {
    NTYTContentTypeUnresolved = 0,
    NTYTContentTypeVideo,
    NTYTContentTypePost,
    NTYTContentTypePlaylistNormal,
    NTYTContentTypePlaylistMix,
};

typedef NS_ENUM(NSInteger, NTYTMetadataValueState) {
    NTYTMetadataValueStateAvailable = 0,
    NTYTMetadataValueStateAbsent,
    NTYTMetadataValueStateUnavailable,
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
    NTYTListIDPostContent,
    NTYTListIDPostChannel,
    NTYTListIDPlaylistTitle,
    NTYTListIDPlaylistChannel,
    NTYTListIDPlaylistID,
    NTYTListIDGlobalBlock,
    NTYTListIDGlobalAllow,
};

typedef NS_ENUM(NSInteger, NTYTListKind) {
    NTYTListKindBlock = 0,
    NTYTListKindAllow = 1,
};

typedef NS_ENUM(NSInteger, NTYTTargetKind) {
    NTYTTargetKindGeneral = 0,
    NTYTTargetKindTitle,
    NTYTTargetKindChannel,
    NTYTTargetKindVideoID,
    NTYTTargetKindPostBody,
    NTYTTargetKindPlaylistID,
    NTYTTargetKindGlobal,
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
    NTYTModifierKindPost = 3,
    NTYTModifierKindPlaylist = 4,
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

typedef NS_ENUM(NSInteger, NTYTMutationFailureReason) {
    NTYTMutationFailureReasonNone = 0,
    NTYTMutationFailureReasonExpressionNotText,
    NTYTMutationFailureReasonDSLParseFailed,
    NTYTMutationFailureReasonDuplicateExpression,
    NTYTMutationFailureReasonRuleNotFound,
    NTYTMutationFailureReasonSelectedRuleMissing,
    NTYTMutationFailureReasonInvalidList,
    NTYTMutationFailureReasonNoRulesSelected,
    NTYTMutationFailureReasonDuplicateRuleIdentifiers,
    NTYTMutationFailureReasonInvalidDestinationPosition,
    NTYTMutationFailureReasonUnsupportedOption,
    NTYTMutationFailureReasonMutationProtected,
    NTYTMutationFailureReasonSnapshotBuildFailed,
    NTYTMutationFailureReasonPersistenceFailed,
};

FOUNDATION_EXPORT NTYTMatchResult NTYTNegateMatchResult(NTYTMatchResult result);
FOUNDATION_EXPORT NSString *NTYTSettingsLifecycleDescription(NTYTSettingsLifecycleState state);

NS_ASSUME_NONNULL_END
