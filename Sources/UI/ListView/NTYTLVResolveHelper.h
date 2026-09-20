#import "NTYTRuleListViewController.h"

@class NTYTRuleListItem;

NS_ASSUME_NONNULL_BEGIN

@interface NTYTRuleListViewController (NTYTLVResolveHelper)
- (nullable NTYTRuleListItem *)resolvedItemForIndexPath:(nullable NSIndexPath *)indexPath;
- (nullable NTYTRuleListItem *)itemWithIdentifier:(NSUUID *)identifier;
- (NSArray<NSUUID *> *)resolvedIdentifiersForIndexPaths:(NSArray<NSIndexPath *> *)indexPaths;
@end

NS_ASSUME_NONNULL_END