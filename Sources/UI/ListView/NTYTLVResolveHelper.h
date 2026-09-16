#import "NTYTRuleListViewController.h"

@class NTYTRuleListItem;

@interface NTYTRuleListViewController (NTYTLVResolveHelper)
- (nullable NTYTRuleListItem *)resolvedItemForIndexPath:(nullable NSIndexPath *)indexPath;
- (nullable NTYTRuleListItem *)itemWithIdentifier:(NSUUID *)identifier;
- (NSArray<NSUUID *> *)resolvedIdentifiersForIndexPaths:(NSArray<NSIndexPath *> *)indexPaths;
@end
