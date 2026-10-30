#import "NTYTStoredSettings.h"

#import "Core/NTYTListDefinition.h"

@implementation NTYTStoredRule

- (instancetype)initWithIdentifier:(NSUUID *)identifier expression:(NSString *)expression {
    self = [super init];
    if (self) {
        _identifier = identifier;
        _expression = [expression copy];
    }
    return self;
}

@end

@implementation NTYTStoredList

- (instancetype)initWithOptionOverrides:(NSDictionary<NSNumber *,NSNumber *> *)optionOverrides
                                   ruleSequence:(NSArray<NTYTStoredRule *> *)ruleSequence {
    self = [super init];
    if (self) {
        _optionOverrides = [optionOverrides copy];
        _ruleSequence = [ruleSequence copy];
    }
    return self;
}

@end

@implementation NTYTStoredSettings

- (instancetype)initWithListStateMap:(NSDictionary<NSNumber *,NTYTStoredList *> *)listStateMap
                       blockOptionState:(NTYTBlockOptionState *)blockOptionState {
    self = [super init];
    if (self) {
        _listStateMap = [listStateMap copy];
        NSParameterAssert(blockOptionState);
        _blockOptionState = blockOptionState;
    }
    return self;
}

- (NTYTStoredList *)listForID:(NTYTListID)listID {
    NTYTStoredList *list = self.listStateMap[@(listID)];
    return list ?: [[NTYTStoredList alloc] initWithOptionOverrides:@{} ruleSequence:@[]];
}

+ (instancetype)emptySettings {
    NSMutableDictionary<NSNumber *, NTYTStoredList *> *listStateMap = [NSMutableDictionary dictionary];
    for (NTYTListDefinition *definition in NTYTListDefinition.allDefinitions) {
        listStateMap[@(definition.listID)] =
            [[NTYTStoredList alloc] initWithOptionOverrides:@{} ruleSequence:@[]];
    }
    return [[self alloc] initWithListStateMap:listStateMap blockOptionState:[NTYTBlockOptionState allOffState]];
}

@end

@implementation NTYTRawRuleOccurrence

- (instancetype)initWithRawIdentifier:(id)rawIdentifier rawExpression:(id)rawExpression {
    self = [super init];
    if (self) {
        _rawIdentifier = rawIdentifier;
        _rawExpression = rawExpression;
    }
    return self;
}

@end

@implementation NTYTRawList

- (instancetype)initWithValidOptionOverrides:(NSDictionary<NSNumber *,NSNumber *> *)validOptionOverrides
                             ruleOccurrences:(NSArray<NTYTRawRuleOccurrence *> *)ruleOccurrences {
    self = [super init];
    if (self) {
        _validOptionOverrides = [validOptionOverrides copy];
        _ruleOccurrences = [ruleOccurrences copy];
    }
    return self;
}

@end

@implementation NTYTRawSettings

- (instancetype)initWithAbsent:(BOOL)absent
                  baseDegraded:(BOOL)baseDegraded
                         listStateMap:(NSDictionary<NSNumber *,NTYTRawList *> *)listStateMap
                       blockOptionState:(NTYTBlockOptionState *)blockOptionState {
    self = [super init];
    if (self) {
        _absent = absent;
        _baseDegraded = baseDegraded;
        _listStateMap = [listStateMap copy];
        NSParameterAssert(blockOptionState);
        _blockOptionState = blockOptionState;
    }
    return self;
}

@end
