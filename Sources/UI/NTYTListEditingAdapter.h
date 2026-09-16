#import <Foundation/Foundation.h>

#import "Core/NTYTTypes.h"

@class NTYTMutationResult;
@class NTYTRuleListItem;

NS_ASSUME_NONNULL_BEGIN

@interface NTYTListEditingAdapter : NSObject

@property(nonatomic, readonly) NTYTListID listID;

- (instancetype)initWithListID:(NTYTListID)listID NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
- (NSArray<NTYTRuleListItem *> *)loadItems;
- (BOOL)mutationsAllowed;
- (NTYTSettingsLifecycleState)lifecycleState;
- (NTYTMutationResult *)addRawExpression:(NSString *)rawExpression;
- (NTYTMutationResult *)editIdentifier:(NSUUID *)identifier
                         rawExpression:(NSString *)rawExpression;
- (NTYTMutationResult *)deleteIdentifier:(NSUUID *)identifier;
- (NTYTMutationResult *)deleteIdentifiers:(NSArray<NSUUID *> *)identifiers;
- (NTYTMutationResult *)moveIdentifier:(NSUUID *)identifier toIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
