#import <Foundation/Foundation.h>

#import "Core/NTYTTypes.h"

@class NTYTStoredRule;
@class NTYTPreparedImport;
@class NTYTExportCapture;

NS_ASSUME_NONNULL_BEGIN

@interface NTYTMutationResult : NSObject

@property(nonatomic, readonly, getter=isSuccess) BOOL success;
@property(nonatomic, readonly, getter=isNoChange) BOOL noChange;
@property(nonatomic, readonly) NTYTMutationErrorCode errorCode;
@property(nonatomic, readonly) NTYTMutationFailureReason failureReason;
@property(nonatomic, strong, readonly, nullable) NSError *underlyingError;

+ (instancetype)successResult;
+ (instancetype)noChangeResult;
+ (instancetype)failureWithCode:(NTYTMutationErrorCode)code
                         reason:(NTYTMutationFailureReason)reason
                underlyingError:(nullable NSError *)underlyingError;

@end

typedef NS_ENUM(NSInteger, NTYTImportCommitStatus) {
    NTYTImportCommitStatusSuccess = 0,
    NTYTImportCommitStatusNoChange,
    NTYTImportCommitStatusConfirmationRequired,
    NTYTImportCommitStatusFailure,
};

@interface NTYTImportCommitResult : NSObject

@property(nonatomic, readonly) NTYTImportCommitStatus status;
@property(nonatomic, strong, readonly, nullable) NSUUID *confirmationToken;
@property(nonatomic, readonly) NTYTSettingsLifecycleState destinationLifecycle;
@property(nonatomic, strong, readonly, nullable) NSError *error;

@end

@interface NTYTSettingsCoordinator : NSObject

+ (instancetype)sharedCoordinator;

- (NTYTSettingsLifecycleState)lifecycleState;
- (BOOL)mutationsAllowed;
- (NSArray<NTYTStoredRule *> *)rulesForListID:(NTYTListID)listID;
- (BOOL)effectiveValueForOption:(NTYTListOptionID)optionID listID:(NTYTListID)listID;
- (BOOL)hideMixEnabled;

- (NTYTMutationResult *)addExpression:(NSString *)rawExpression listID:(NTYTListID)listID;
- (NTYTMutationResult *)editRuleID:(NSUUID *)ruleID
                        expression:(NSString *)rawExpression
                            listID:(NTYTListID)listID;
- (NTYTMutationResult *)deleteRuleID:(NSUUID *)ruleID listID:(NTYTListID)listID;
- (NTYTMutationResult *)deleteRuleIDs:(NSArray<NSUUID *> *)ruleIDs listID:(NTYTListID)listID;
- (NTYTMutationResult *)moveRuleID:(NSUUID *)ruleID
                           toIndex:(NSUInteger)destinationIndex
                            listID:(NTYTListID)listID;
- (NTYTMutationResult *)setEffectiveValue:(BOOL)value
                                forOption:(NTYTListOptionID)optionID
                                    listID:(NTYTListID)listID;
- (NTYTMutationResult *)setHideMixEnabled:(BOOL)enabled;

// A nil token starts an attempt; a returned token authorizes only that destination state.
- (NTYTImportCommitResult *)commitPreparedImport:(NTYTPreparedImport *)prepared
                                confirmationToken:(nullable NSUUID *)token;
- (nullable NTYTExportCapture *)captureSettingsForExport;

@end

NS_ASSUME_NONNULL_END
