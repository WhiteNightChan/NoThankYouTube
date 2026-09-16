#import <Foundation/Foundation.h>

#import "NTYTListDefinition.h"
#import "NTYTTypes.h"

NS_ASSUME_NONNULL_BEGIN

@interface NTYTMatcher : NSObject

@property(nonatomic, readonly) NTYTMatcherKind kind;
@property(nonatomic, copy, readonly, nullable) NSString *plainText;
@property(nonatomic, strong, readonly, nullable) NSRegularExpression *regularExpression;

+ (instancetype)plainMatcherWithText:(NSString *)text;
+ (instancetype)regexMatcherWithExpression:(NSRegularExpression *)regularExpression;

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
+ (instancetype)videoModifierNegative:(BOOL)negative;

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
@property(nonatomic, strong, readonly) NTYTMatchOptions *options;
@property(nonatomic, copy, readonly) NSArray<NTYTRuntimeRule *> *rules;

- (instancetype)initWithListID:(NTYTListID)listID
                        options:(NTYTMatchOptions *)options
                          rules:(NSArray<NTYTRuntimeRule *> *)rules NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

@interface NTYTRuntimeSettingsSnapshot : NSObject

@property(nonatomic, copy, readonly) NSDictionary<NSNumber *, NTYTRuntimeListState *> *listStates;

- (instancetype)initWithListStates:(NSDictionary<NSNumber *, NTYTRuntimeListState *> *)listStates NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
- (NTYTRuntimeListState *)stateForListID:(NTYTListID)listID;
+ (instancetype)emptySnapshot;

@end

NS_ASSUME_NONNULL_END
