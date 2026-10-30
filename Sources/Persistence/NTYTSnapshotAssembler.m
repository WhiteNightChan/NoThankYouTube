#import "NTYTSnapshotAssembler.h"

#import "Core/NTYTListDefinition.h"
#import "Core/NTYTRuntimeModel.h"
#import "DSL/NTYTDSLParser.h"
#import "NTYTStoredSettings.h"

NSErrorDomain const NTYTSnapshotAssemblerErrorDomain = @"com.whitenightchan.nothankyoutube.snapshot";

static NSError *NTYTAssemblyError(NSString *message) {
    return [NSError errorWithDomain:NTYTSnapshotAssemblerErrorDomain
                               code:1
                           userInfo:@{NSLocalizedDescriptionKey: message}];
}

@implementation NTYTSnapshotAssemblyResult

- (instancetype)initWithAcceptedSettings:(NTYTStoredSettings *)acceptedSettings
                                  snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot
                            hadDegradation:(BOOL)hadDegradation {
    self = [super init];
    if (self) {
        _acceptedSettings = acceptedSettings;
        _snapshot = snapshot;
        _hadDegradation = hadDegradation;
    }
    return self;
}

@end

@implementation NTYTSnapshotAssembler

+ (NTYTSnapshotAssemblyResult *)assembleRawSettings:(NTYTRawSettings *)rawSettings
                                               error:(NSError **)error {
    if (!rawSettings) {
        if (error) {
            *error = NTYTAssemblyError(@"Raw settings are unavailable.");
        }
        return nil;
    }

    @try {
        __block BOOL degraded = rawSettings.baseDegraded;
        NTYTBlockOptionState *blockOptionState = rawSettings.blockOptionState;
        if (![blockOptionState isKindOfClass:[NTYTBlockOptionState class]]) {
            degraded = YES;
            blockOptionState = [NTYTBlockOptionState allOffState];
        }
        NSMutableSet<NSString *> *acceptedUUIDs = [NSMutableSet set];
        NSMutableDictionary<NSNumber *, NTYTStoredList *> *storedListStateMap =
            [NSMutableDictionary dictionary];
        NSMutableDictionary<NSNumber *, NTYTRuntimeListState *> *runtimeListStateMap =
            [NSMutableDictionary dictionary];

        for (NTYTListDefinition *definition in NTYTListDefinition.allDefinitions) {
            NTYTRawList *rawList = rawSettings.listStateMap[@(definition.listID)];
            if (!rawList) {
                degraded = YES;
                rawList = [[NTYTRawList alloc] initWithValidOptionOverrides:@{}
                                                            ruleOccurrences:@[]];
            }

            NSMutableDictionary<NSNumber *, NSNumber *> *acceptedOverrides =
                [NSMutableDictionary dictionary];
            [rawList.validOptionOverrides enumerateKeysAndObjectsUsingBlock:^(NSNumber *optionID,
                                                                              NSNumber *value,
                                                                              BOOL *stop) {
                if (![definition.supportedOptionIDs containsObject:optionID] ||
                    ![value isKindOfClass:[NSNumber class]]) {
                    degraded = YES;
                    return;
                }
                acceptedOverrides[optionID] = @([value boolValue]);
            }];

            BOOL caseSensitive = definition.defaultMatchOptionState.caseSensitive;
            BOOL exactMatch = definition.defaultMatchOptionState.exactMatch;
            NSNumber *caseOverride = acceptedOverrides[@(NTYTListOptionIDCaseSensitive)];
            NSNumber *exactOverride = acceptedOverrides[@(NTYTListOptionIDExactMatch)];
            if (caseOverride) {
                caseSensitive = caseOverride.boolValue;
            }
            if (exactOverride) {
                exactMatch = exactOverride.boolValue;
            }
            NTYTMatchOptionState *effectiveMatchOptionState =
                [[NTYTMatchOptionState alloc] initWithCaseSensitive:caseSensitive
                                                     exactMatch:exactMatch];

            NSMutableSet<NSString *> *acceptedExpressionKeys = [NSMutableSet set];
            NSMutableArray<NTYTStoredRule *> *storedRuleSequence = [NSMutableArray array];
            NSMutableArray<NTYTRuntimeRule *> *runtimeRuleSequence = [NSMutableArray array];

            for (NTYTRawRuleOccurrence *occurrence in rawList.ruleOccurrences) {
                if (![occurrence.rawIdentifier isKindOfClass:[NSString class]] ||
                    ![occurrence.rawExpression isKindOfClass:[NSString class]]) {
                    degraded = YES;
                    continue;
                }

                NSUUID *identifier =
                    [[NSUUID alloc] initWithUUIDString:(NSString *)occurrence.rawIdentifier];
                NSString *expression = (NSString *)occurrence.rawExpression;
                if (!identifier) {
                    degraded = YES;
                    continue;
                }

                NSError *parseError = nil;
                NTYTRuntimeRule *runtimeRule =
                    [NTYTDSLParser parseExpression:expression
                                        identifier:identifier
                                             error:&parseError];
                if (!runtimeRule) {
                    degraded = YES;
                    continue;
                }

                NSString *uuidKey = identifier.UUIDString;
                if ([acceptedUUIDs containsObject:uuidKey]) {
                    degraded = YES;
                    continue;
                }

                NSString *expressionKey =
                    [expression stringByTrimmingCharactersInSet:
                        [NSCharacterSet whitespaceAndNewlineCharacterSet]];
                if ([acceptedExpressionKeys containsObject:expressionKey]) {
                    degraded = YES;
                    continue;
                }

                [acceptedUUIDs addObject:uuidKey];
                [acceptedExpressionKeys addObject:expressionKey];
                [storedRuleSequence addObject:[[NTYTStoredRule alloc]
                    initWithIdentifier:identifier expression:expression]];
                [runtimeRuleSequence addObject:runtimeRule];
            }

            storedListStateMap[@(definition.listID)] =
                [[NTYTStoredList alloc] initWithOptionOverrides:acceptedOverrides
                                                          ruleSequence:storedRuleSequence];
            runtimeListStateMap[@(definition.listID)] =
                [[NTYTRuntimeListState alloc] initWithListID:definition.listID
                                                     matchOptionState:effectiveMatchOptionState
                                                       ruleSequence:runtimeRuleSequence];
        }

        NTYTStoredSettings *acceptedSettings =
            [[NTYTStoredSettings alloc] initWithListStateMap:storedListStateMap
                                              blockOptionState:blockOptionState];
        NTYTRuntimeSettingsSnapshot *snapshot =
            [[NTYTRuntimeSettingsSnapshot alloc] initWithListStates:runtimeListStateMap
                                                            blockOptionState:blockOptionState];
        return [[NTYTSnapshotAssemblyResult alloc]
            initWithAcceptedSettings:acceptedSettings
                             snapshot:snapshot
                       hadDegradation:degraded];
    } @catch (NSException *exception) {
        if (error) {
            *error = NTYTAssemblyError(exception.reason ?: @"Snapshot assembly failed.");
        }
        return nil;
    }
}

+ (NTYTRuntimeSettingsSnapshot *)buildStrictSnapshotForSettings:(NTYTStoredSettings *)settings
                                                           error:(NSError **)error {
    if (!settings) {
        if (error) {
            *error = NTYTAssemblyError(@"Candidate settings are unavailable.");
        }
        return nil;
    }

    NSMutableDictionary<NSNumber *, NTYTRawList *> *rawListStateMap = [NSMutableDictionary dictionary];
    for (NTYTListDefinition *definition in NTYTListDefinition.allDefinitions) {
        NTYTStoredList *storedList = [settings listForID:definition.listID];
        NSMutableArray<NTYTRawRuleOccurrence *> *occurrences = [NSMutableArray array];
        for (NTYTStoredRule *rule in storedList.ruleSequence) {
            [occurrences addObject:[[NTYTRawRuleOccurrence alloc]
                initWithRawIdentifier:rule.identifier.UUIDString
                        rawExpression:rule.expression]];
        }
        rawListStateMap[@(definition.listID)] =
            [[NTYTRawList alloc] initWithValidOptionOverrides:storedList.optionOverrides
                                               ruleOccurrences:occurrences];
    }

    NTYTRawSettings *raw = [[NTYTRawSettings alloc] initWithAbsent:NO
                                                     baseDegraded:NO
                                                            listStateMap:rawListStateMap
                                                          blockOptionState:settings.blockOptionState];
    NSError *assemblyError = nil;
    NTYTSnapshotAssemblyResult *result = [self assembleRawSettings:raw error:&assemblyError];
    if (!result || result.hadDegradation) {
        if (error) {
            *error = assemblyError ?: NTYTAssemblyError(@"The candidate settings violate a runtime invariant.");
        }
        return nil;
    }
    return result.snapshot;
}

@end
