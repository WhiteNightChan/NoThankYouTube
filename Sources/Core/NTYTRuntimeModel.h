#import <Foundation/Foundation.h>

#import "NTYTListDefinition.h"
#import "NTYTTypes.h"
#import "NTYTBlockOptionState.h"

NS_ASSUME_NONNULL_BEGIN

@interface NTYTMatcher : NSObject

@property(nonatomic, readonly) NTYTMatcherKind kind;
@property(nonatomic, copy, readonly, nullable) NSString *plainText;
@property(nonatomic, strong, readonly, nullable) NSRegularExpression *regularExpression;

+ (instancetype)plainMatcherWithText:(NSString *)text;
+ (instancetype)regexMatcherWithExpression:(NSRegularExpression *)regularExpression;
- (instancetype)init NS_UNAVAILABLE;

@end

@interface NTYTMatcherExpression : NSObject

@property(nonatomic, strong, readonly) NTYTMatcher *matcher;
@property(nonatomic, readonly, getter=isNegative) BOOL negative;

- (instancetype)initWithMatcher:(NTYTMatcher *)matcher
                        negative:(BOOL)negative NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

@interface NTYTModifier : NSObject

@property(nonatomic, readonly) NTYTModifierKind kind;
@property(nonatomic, readonly, getter=isNegative) BOOL negative;
@property(nonatomic, strong, readonly, nullable) NTYTMatcherExpression *matcherExpression;

+ (instancetype)matcherModifierWithKind:(NTYTModifierKind)kind
                                negative:(BOOL)negative
                       matcherExpression:(NTYTMatcherExpression *)matcherExpression;
+ (instancetype)predicateModifierWithKind:(NTYTModifierKind)kind
                                  negative:(BOOL)negative;
- (instancetype)init NS_UNAVAILABLE;

@end

@interface NTYTRuntimeRule : NSObject

@property(nonatomic, strong, readonly) NSUUID *identifier;
@property(nonatomic, strong, readonly) NTYTMatcherExpression *mainMatcher;
@property(nonatomic, copy, readonly) NSArray<NTYTModifier *> *modifiers;

- (instancetype)initWithIdentifier:(NSUUID *)identifier
                        mainMatcher:(NTYTMatcherExpression *)mainMatcher
                          modifiers:(NSArray<NTYTModifier *> *)modifiers NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

@interface NTYTRuntimeListState : NSObject

@property(nonatomic, readonly) NTYTListID listID;
@property(nonatomic, strong, readonly) NTYTMatchOptionState *matchOptionState;
@property(nonatomic, copy, readonly) NSArray<NTYTRuntimeRule *> *ruleSequence;

- (instancetype)initWithListID:(NTYTListID)listID
                        matchOptionState:(NTYTMatchOptionState *)matchOptionState
                          ruleSequence:(NSArray<NTYTRuntimeRule *> *)ruleSequence NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

@interface NTYTRuntimeSettingsSnapshot : NSObject

@property(nonatomic, copy, readonly) NSDictionary<NSNumber *, NTYTRuntimeListState *> *listStateMap;
@property(nonatomic, strong, readonly) NTYTBlockOptionState *blockOptionState;

- (instancetype)initWithListStateMap:(NSDictionary<NSNumber *, NTYTRuntimeListState *> *)listStateMap
                       blockOptionState:(NTYTBlockOptionState *)blockOptionState NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
- (nullable NTYTRuntimeListState *)stateForListID:(NTYTListID)listID;
+ (instancetype)emptySnapshot;

@end

NS_ASSUME_NONNULL_END
