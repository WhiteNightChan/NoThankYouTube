#import "NTYTRuntimeModel.h"

@interface NTYTMatcher ()

- (instancetype)initWithKind:(NTYTMatcherKind)kind
                    plainText:(nullable NSString *)plainText
            regularExpression:(nullable NSRegularExpression *)regularExpression;

@end

@implementation NTYTMatcher

- (instancetype)initWithKind:(NTYTMatcherKind)kind
                    plainText:(NSString *)plainText
            regularExpression:(NSRegularExpression *)regularExpression {
    self = [super init];
    if (self) {
        _kind = kind;
        _plainText = [plainText copy];
        _regularExpression = regularExpression;
    }
    return self;
}

+ (instancetype)plainMatcherWithText:(NSString *)text {
    return [[self alloc] initWithKind:NTYTMatcherKindPlain
                           plainText:text
                   regularExpression:nil];
}

+ (instancetype)regexMatcherWithExpression:(NSRegularExpression *)regularExpression {
    return [[self alloc] initWithKind:NTYTMatcherKindRegex
                           plainText:nil
                   regularExpression:regularExpression];
}

@end

@implementation NTYTMatcherExpression

- (instancetype)initWithMatcher:(NTYTMatcher *)matcher negative:(BOOL)negative {
    self = [super init];
    if (self) {
        _matcher = matcher;
        _negative = negative;
    }
    return self;
}

@end

@interface NTYTModifier ()

- (instancetype)initWithKind:(NTYTModifierKind)kind
                     negative:(BOOL)negative
            matcherExpression:(nullable NTYTMatcherExpression *)matcherExpression;

@end

@implementation NTYTModifier

- (instancetype)initWithKind:(NTYTModifierKind)kind
                     negative:(BOOL)negative
            matcherExpression:(NTYTMatcherExpression *)matcherExpression {
    self = [super init];
    if (self) {
        _kind = kind;
        _negative = negative;
        _matcherExpression = matcherExpression;
    }
    return self;
}

+ (instancetype)matcherModifierWithKind:(NTYTModifierKind)kind
                                negative:(BOOL)negative
                       matcherExpression:(NTYTMatcherExpression *)matcherExpression {
    return [[self alloc] initWithKind:kind
                            negative:negative
                   matcherExpression:matcherExpression];
}

+ (instancetype)predicateModifierWithKind:(NTYTModifierKind)kind
                                  negative:(BOOL)negative {
    NSParameterAssert(kind == NTYTModifierKindVideo ||
                      kind == NTYTModifierKindPost ||
                      kind == NTYTModifierKindPlaylist ||
                      kind == NTYTModifierKindShorts ||
                      kind == NTYTModifierKindStation ||
                      kind == NTYTModifierKindUpcoming ||
                      kind == NTYTModifierKindCurrent);
    return [[self alloc] initWithKind:kind
                            negative:negative
                   matcherExpression:nil];
}

@end

@implementation NTYTRuntimeRule

- (instancetype)initWithIdentifier:(NSUUID *)identifier
                        mainMatcher:(NTYTMatcherExpression *)mainMatcher
                          modifiers:(NSArray<NTYTModifier *> *)modifiers {
    self = [super init];
    if (self) {
        _identifier = identifier;
        _mainMatcher = mainMatcher;
        _modifiers = [modifiers copy];
    }
    return self;
}

@end

@implementation NTYTRuntimeListState

- (instancetype)initWithListID:(NTYTListID)listID
                        matchOptionState:(NTYTMatchOptionState *)matchOptionState
                          ruleSequence:(NSArray<NTYTRuntimeRule *> *)ruleSequence {
    self = [super init];
    if (self) {
        _listID = listID;
        _matchOptionState = matchOptionState;
        _ruleSequence = [ruleSequence copy];
    }
    return self;
}

@end

@implementation NTYTRuntimeSettingsSnapshot

- (instancetype)initWithListStateMap:(NSDictionary<NSNumber *,NTYTRuntimeListState *> *)listStateMap
                       blockOptionState:(NTYTBlockOptionState *)blockOptionState {
    self = [super init];
    if (self) {
        _listStateMap = [listStateMap copy];
        NSParameterAssert(blockOptionState);
        _blockOptionState = blockOptionState;
    }
    return self;
}

- (nullable NTYTRuntimeListState *)stateForListID:(NTYTListID)listID {
    return self.listStateMap[@(listID)];
}

+ (instancetype)emptySnapshot {
    NSMutableDictionary<NSNumber *, NTYTRuntimeListState *> *emptyListStateMap =
        [NSMutableDictionary dictionary];
    for (NTYTListDefinition *definition in NTYTListDefinition.allDefinitions) {
        emptyListStateMap[@(definition.listID)] =
            [[NTYTRuntimeListState alloc] initWithListID:definition.listID
                                                 matchOptionState:definition.defaultMatchOptionState
                                                   ruleSequence:@[]];
    }
    return [[self alloc] initWithListStateMap:emptyListStateMap blockOptionState:[NTYTBlockOptionState allOffState]];
}

@end
