#import <Foundation/Foundation.h>

#import "Core/NTYTTypes.h"
#import "Core/NTYTBlockOptionState.h"

NS_ASSUME_NONNULL_BEGIN

@interface NTYTStoredRule : NSObject

@property(nonatomic, strong, readonly) NSUUID *identifier;
@property(nonatomic, copy, readonly) NSString *expression;

- (instancetype)initWithIdentifier:(NSUUID *)identifier
                         expression:(NSString *)expression NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

@interface NTYTStoredList : NSObject

@property(nonatomic, copy, readonly) NSDictionary<NSNumber *, NSNumber *> *optionOverrides;
@property(nonatomic, copy, readonly) NSArray<NTYTStoredRule *> *ruleSequence;

- (instancetype)initWithOptionOverrides:(NSDictionary<NSNumber *, NSNumber *> *)optionOverrides
                                   ruleSequence:(NSArray<NTYTStoredRule *> *)ruleSequence NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

@interface NTYTStoredSettings : NSObject

@property(nonatomic, copy, readonly) NSDictionary<NSNumber *, NTYTStoredList *> *listStateMap;
@property(nonatomic, strong, readonly) NTYTBlockOptionState *blockOptionState;

- (instancetype)initWithListStateMap:(NSDictionary<NSNumber *, NTYTStoredList *> *)listStateMap
                       blockOptionState:(NTYTBlockOptionState *)blockOptionState NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
- (NTYTStoredList *)listForID:(NTYTListID)listID;
+ (instancetype)emptySettings;

@end

@interface NTYTRawRuleOccurrence : NSObject

@property(nonatomic, strong, readonly, nullable) id rawIdentifier;
@property(nonatomic, strong, readonly, nullable) id rawExpression;

- (instancetype)initWithRawIdentifier:(nullable id)rawIdentifier
                         rawExpression:(nullable id)rawExpression NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

@interface NTYTRawList : NSObject

@property(nonatomic, copy, readonly) NSDictionary<NSNumber *, NSNumber *> *validOptionOverrides;
@property(nonatomic, copy, readonly) NSArray<NTYTRawRuleOccurrence *> *ruleOccurrences;

- (instancetype)initWithValidOptionOverrides:(NSDictionary<NSNumber *, NSNumber *> *)validOptionOverrides
                             ruleOccurrences:(NSArray<NTYTRawRuleOccurrence *> *)ruleOccurrences NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

@interface NTYTRawSettings : NSObject

@property(nonatomic, readonly) BOOL baseDegraded;
@property(nonatomic, copy, readonly) NSDictionary<NSNumber *, NTYTRawList *> *listStateMap;
@property(nonatomic, strong, readonly) NTYTBlockOptionState *blockOptionState;

- (instancetype)initWithListStateMap:(NSDictionary<NSNumber *, NTYTRawList *> *)listStateMap
                        baseDegraded:(BOOL)baseDegraded
                    blockOptionState:(NTYTBlockOptionState *)blockOptionState NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
