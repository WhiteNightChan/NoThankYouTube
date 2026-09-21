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
                                   rules:(NSArray<NTYTStoredRule *> *)rules {
    self = [super init];
    if (self) {
        _optionOverrides = [optionOverrides copy];
        _rules = [rules copy];
    }
    return self;
}

@end

@implementation NTYTStoredSettings

- (instancetype)initWithLists:(NSDictionary<NSNumber *,NTYTStoredList *> *)lists
                       hideMix:(BOOL)hideMix {
    self = [super init];
    if (self) {
        _lists = [lists copy];
        _hideMix = hideMix;
    }
    return self;
}

- (NTYTStoredList *)listForID:(NTYTListID)listID {
    NTYTStoredList *list = self.lists[@(listID)];
    return list ?: [[NTYTStoredList alloc] initWithOptionOverrides:@{} rules:@[]];
}

+ (instancetype)emptySettings {
    NSMutableDictionary<NSNumber *, NTYTStoredList *> *lists = [NSMutableDictionary dictionary];
    for (NTYTListDefinition *definition in NTYTListDefinition.allDefinitions) {
        lists[@(definition.listID)] =
            [[NTYTStoredList alloc] initWithOptionOverrides:@{} rules:@[]];
    }
    return [[self alloc] initWithLists:lists hideMix:NO];
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
                         lists:(NSDictionary<NSNumber *,NTYTRawList *> *)lists
                       hideMix:(BOOL)hideMix {
    self = [super init];
    if (self) {
        _absent = absent;
        _baseDegraded = baseDegraded;
        _lists = [lists copy];
        _hideMix = hideMix;
    }
    return self;
}

@end
