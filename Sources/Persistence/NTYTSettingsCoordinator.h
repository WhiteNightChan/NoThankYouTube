#import <Foundation/Foundation.h>

#import "Core/NTYTTypes.h"

@class NTYTStoredRule;

NS_ASSUME_NONNULL_BEGIN

@interface NTYTMutationResult : NSObject

@property(nonatomic, readonly, getter=isSuccess) BOOL success;
@property(nonatomic, readonly, getter=isNoChange) BOOL noChange;
@property(nonatomic, readonly) NTYTMutationErrorCode errorCode;
@property(nonatomic, copy, readonly) NSString *message;

+ (instancetype)successResult;
+ (instancetype)noChangeResult;
+ (instancetype)failureWithCode:(NTYTMutationErrorCode)code message:(NSString *)message;

@end

@interface NTYTSettingsCoordinator : NSObject

+ (instancetype)sharedCoordinator;

- (NTYTSettingsLifecycleState)lifecycleState;
- (BOOL)mutationsAllowed;
- (NSArray<NTYTStoredRule *> *)rulesForListID:(NTYTListID)listID;
- (BOOL)effectiveValueForOption:(NTYTListOptionID)optionID listID:(NTYTListID)listID;

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

@end

NS_ASSUME_NONNULL_END
