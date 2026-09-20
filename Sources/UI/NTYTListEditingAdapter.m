#import "NTYTListEditingAdapter.h"

#import "NTYTRuleListItem.h"
#import "Persistence/NTYTSettingsCoordinator.h"
#import "Persistence/NTYTStoredSettings.h"

@implementation NTYTListEditingAdapter

- (instancetype)initWithListID:(NTYTListID)listID {
    self = [super init];
    if (self) {
        _listID = listID;
    }
    return self;
}

- (NSArray<NTYTRuleListItem *> *)loadItems {
    NSArray<NTYTStoredRule *> *rules =
        [[NTYTSettingsCoordinator sharedCoordinator] rulesForListID:self.listID];
    NSMutableArray<NTYTRuleListItem *> *items = [NSMutableArray arrayWithCapacity:rules.count];
    for (NTYTStoredRule *rule in rules) {
        [items addObject:[[NTYTRuleListItem alloc] initWithIdentifier:rule.identifier
                                                                text:rule.expression]];
    }
    return items;
}

- (BOOL)mutationsAllowed {
    return [[NTYTSettingsCoordinator sharedCoordinator] mutationsAllowed];
}

- (NTYTSettingsLifecycleState)lifecycleState {
    return [[NTYTSettingsCoordinator sharedCoordinator] lifecycleState];
}

- (NTYTMutationResult *)addRawExpression:(NSString *)rawExpression {
    return [[NTYTSettingsCoordinator sharedCoordinator]
        addExpression:rawExpression listID:self.listID];
}

- (NTYTMutationResult *)editIdentifier:(NSUUID *)identifier
                         rawExpression:(NSString *)rawExpression {
    return [[NTYTSettingsCoordinator sharedCoordinator]
        editRuleID:identifier expression:rawExpression listID:self.listID];
}

- (NTYTMutationResult *)deleteIdentifier:(NSUUID *)identifier {
    return [[NTYTSettingsCoordinator sharedCoordinator]
        deleteRuleID:identifier listID:self.listID];
}

- (NTYTMutationResult *)deleteIdentifiers:(NSArray<NSUUID *> *)identifiers {
    return [[NTYTSettingsCoordinator sharedCoordinator]
        deleteRuleIDs:identifiers listID:self.listID];
}

- (NTYTMutationResult *)moveIdentifier:(NSUUID *)identifier toIndex:(NSUInteger)index {
    return [[NTYTSettingsCoordinator sharedCoordinator]
        moveRuleID:identifier toIndex:index listID:self.listID];
}

@end
