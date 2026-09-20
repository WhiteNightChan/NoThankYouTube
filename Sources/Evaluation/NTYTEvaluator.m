#import "NTYTEvaluator.h"

#import "Core/NTYTContentMetadata.h"
#import "Core/NTYTListDefinition.h"
#import "Core/NTYTRuntimeModel.h"

@interface NTYTEvaluator ()

+ (NTYTMatchResult)evaluatePhaseLists:(NSArray<NSNumber *> *)listIDs
                              metadata:(NTYTContentMetadata *)metadata
                              snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot
                       internalFailure:(BOOL *)internalFailure;
+ (NTYTMatchResult)evaluateList:(NTYTRuntimeListState *)listState
                     definition:(NTYTListDefinition *)definition
                       metadata:(NTYTContentMetadata *)metadata
                       snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot
                internalFailure:(BOOL *)internalFailure;
+ (NTYTMatchResult)evaluateRule:(NTYTRuntimeRule *)rule
                     definition:(NTYTListDefinition *)definition
                        options:(NTYTMatchOptions *)options
                       metadata:(NTYTContentMetadata *)metadata
                       snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot
                internalFailure:(BOOL *)internalFailure;
+ (NTYTMatchResult)evaluateMainExpression:(NTYTMatcherExpression *)expression
                               targetKind:(NTYTTargetKind)targetKind
                                  options:(NTYTMatchOptions *)options
                                 metadata:(NTYTContentMetadata *)metadata
                          internalFailure:(BOOL *)internalFailure;
+ (NTYTMatchResult)evaluateModifier:(NTYTModifier *)modifier
                         owningListKind:(NTYTListKind)owningListKind
                           metadata:(NTYTContentMetadata *)metadata
                           snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot
                    internalFailure:(BOOL *)internalFailure;
+ (nullable NTYTMatchOptions *)modifierOptionsForKind:(NTYTModifierKind)modifierKind
                                            owningListKind:(NTYTListKind)owningListKind
                                              snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot
                                       internalFailure:(BOOL *)internalFailure;
+ (NTYTMatchResult)evaluateExpression:(NTYTMatcherExpression *)expression
                            candidate:(nullable NSString *)candidate
                              options:(NTYTMatchOptions *)options
                      internalFailure:(BOOL *)internalFailure;
+ (NTYTMatchResult)evaluateChannelExpression:(NTYTMatcherExpression *)expression
                                    metadata:(NTYTContentMetadata *)metadata
                                     options:(NTYTMatchOptions *)options
                             internalFailure:(BOOL *)internalFailure;
+ (NTYTMatchResult)evaluatePositiveMatcher:(NTYTMatcher *)matcher
                                  candidate:(nullable NSString *)candidate
                                    options:(NTYTMatchOptions *)options
                            internalFailure:(BOOL *)internalFailure;

@end

@implementation NTYTEvaluator

+ (NTYTDecision)decisionForMetadata:(NTYTContentMetadata *)metadata
                            snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot {
    if (!metadata || !snapshot) {
        return NTYTDecisionNoMatch;
    }

    @try {
        BOOL internalFailure = NO;
        NTYTMatchResult allowResult =
            [self evaluatePhaseLists:@[
                @(NTYTListIDGeneralAllow),
                @(NTYTListIDChannelsAllow),
            ]
                             metadata:metadata
                             snapshot:snapshot
                      internalFailure:&internalFailure];
        if (internalFailure) {
            return NTYTDecisionNoMatch;
        }
        if (allowResult == NTYTMatchResultMatch) {
            return NTYTDecisionAllow;
        }
        if (allowResult == NTYTMatchResultUnavailable) {
            return NTYTDecisionNoMatch;
        }

        NTYTMatchResult blockResult =
            [self evaluatePhaseLists:@[
                @(NTYTListIDGeneralBlock),
                @(NTYTListIDVideosTitle),
                @(NTYTListIDVideosChannel),
                @(NTYTListIDVideosID),
                @(NTYTListIDChannelsBlock),
            ]
                             metadata:metadata
                             snapshot:snapshot
                      internalFailure:&internalFailure];
        if (internalFailure) {
            return NTYTDecisionNoMatch;
        }
        return blockResult == NTYTMatchResultMatch
            ? NTYTDecisionBlock
            : NTYTDecisionNoMatch;
    } @catch (__unused NSException *exception) {
        return NTYTDecisionNoMatch;
    }
}

+ (NTYTMatchResult)evaluatePhaseLists:(NSArray<NSNumber *> *)listIDs
                              metadata:(NTYTContentMetadata *)metadata
                              snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot
                       internalFailure:(BOOL *)internalFailure {
    BOOL sawUnavailable = NO;
    for (NSNumber *listNumber in listIDs) {
        NTYTListID listID = (NTYTListID)listNumber.integerValue;
        NTYTListDefinition *definition =
            [NTYTListDefinition definitionForListID:listID];
        NTYTRuntimeListState *state = [snapshot stateForListID:listID];
        if (!definition ||
            !state ||
            state.listID != listID ||
            !state.options ||
            !state.rules) {
            *internalFailure = YES;
            return NTYTMatchResultNoMatch;
        }

        NTYTMatchResult result = [self evaluateList:state
                                         definition:definition
                                           metadata:metadata
                                           snapshot:snapshot
                                    internalFailure:internalFailure];
        if (*internalFailure) {
            return NTYTMatchResultNoMatch;
        }
        if (result == NTYTMatchResultMatch) {
            return NTYTMatchResultMatch;
        }
        if (result == NTYTMatchResultUnavailable) {
            sawUnavailable = YES;
        }
    }
    return sawUnavailable ? NTYTMatchResultUnavailable : NTYTMatchResultNoMatch;
}

+ (NTYTMatchResult)evaluateList:(NTYTRuntimeListState *)listState
                     definition:(NTYTListDefinition *)definition
                       metadata:(NTYTContentMetadata *)metadata
                       snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot
                internalFailure:(BOOL *)internalFailure {
    BOOL sawUnavailable = NO;
    for (NTYTRuntimeRule *rule in listState.rules) {
        NTYTMatchResult result = [self evaluateRule:rule
                                         definition:definition
                                            options:listState.options
                                           metadata:metadata
                                           snapshot:snapshot
                                    internalFailure:internalFailure];
        if (*internalFailure) {
            return NTYTMatchResultNoMatch;
        }
        if (result == NTYTMatchResultMatch) {
            return NTYTMatchResultMatch;
        }
        if (result == NTYTMatchResultUnavailable) {
            sawUnavailable = YES;
        }
    }
    return sawUnavailable ? NTYTMatchResultUnavailable : NTYTMatchResultNoMatch;
}

+ (NTYTMatchResult)evaluateRule:(NTYTRuntimeRule *)rule
                     definition:(NTYTListDefinition *)definition
                        options:(NTYTMatchOptions *)options
                       metadata:(NTYTContentMetadata *)metadata
                       snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot
                internalFailure:(BOOL *)internalFailure {
    if (!rule.identifier ||
        !rule.mainMatcher ||
        !rule.modifiers ||
        !options ||
        !snapshot) {
        *internalFailure = YES;
        return NTYTMatchResultNoMatch;
    }

    BOOL sawUnavailable = NO;
    NTYTMatchResult mainResult =
        [self evaluateMainExpression:rule.mainMatcher
                          targetKind:definition.targetKind
                             options:options
                            metadata:metadata
                     internalFailure:internalFailure];
    if (*internalFailure || mainResult == NTYTMatchResultNoMatch) {
        return NTYTMatchResultNoMatch;
    }
    sawUnavailable = mainResult == NTYTMatchResultUnavailable;

    for (NTYTModifier *modifier in rule.modifiers) {
        NTYTMatchResult modifierResult =
            [self evaluateModifier:modifier
                        owningListKind:definition.listKind
                          metadata:metadata
                          snapshot:snapshot
                   internalFailure:internalFailure];
        if (*internalFailure || modifierResult == NTYTMatchResultNoMatch) {
            return NTYTMatchResultNoMatch;
        }
        if (modifierResult == NTYTMatchResultUnavailable) {
            sawUnavailable = YES;
        }
    }
    return sawUnavailable ? NTYTMatchResultUnavailable : NTYTMatchResultMatch;
}

+ (NTYTMatchResult)evaluateMainExpression:(NTYTMatcherExpression *)expression
                               targetKind:(NTYTTargetKind)targetKind
                                  options:(NTYTMatchOptions *)options
                                 metadata:(NTYTContentMetadata *)metadata
                          internalFailure:(BOOL *)internalFailure {
    switch (targetKind) {
        case NTYTTargetKindTitle:
            return [self evaluateExpression:expression
                                  candidate:metadata.title
                                    options:options
                            internalFailure:internalFailure];
        case NTYTTargetKindChannel:
            return [self evaluateChannelExpression:expression
                                          metadata:metadata
                                           options:options
                                   internalFailure:internalFailure];
        case NTYTTargetKindVideoID:
            return [self evaluateExpression:expression
                                  candidate:metadata.videoID
                                    options:options
                            internalFailure:internalFailure];
    }
    *internalFailure = YES;
    return NTYTMatchResultNoMatch;
}

+ (NTYTMatchResult)evaluateModifier:(NTYTModifier *)modifier
                         owningListKind:(NTYTListKind)owningListKind
                           metadata:(NTYTContentMetadata *)metadata
                           snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot
                    internalFailure:(BOOL *)internalFailure {
    NTYTMatchResult result = NTYTMatchResultNoMatch;
    switch (modifier.kind) {
        case NTYTModifierKindChannel: {
            if (!modifier.matcherExpression) {
                *internalFailure = YES;
                return NTYTMatchResultNoMatch;
            }
            NTYTMatchOptions *options = nil;
            if (modifier.matcherExpression.matcher.kind == NTYTMatcherKindPlain) {
                options = [self modifierOptionsForKind:modifier.kind
                                     owningListKind:owningListKind
                                       snapshot:snapshot
                                internalFailure:internalFailure];
                if (*internalFailure || !options) {
                    return NTYTMatchResultNoMatch;
                }
            }
            result = [self evaluateChannelExpression:modifier.matcherExpression
                                            metadata:metadata
                                             options:options
                                     internalFailure:internalFailure];
            break;
        }
        case NTYTModifierKindContent: {
            if (!modifier.matcherExpression) {
                *internalFailure = YES;
                return NTYTMatchResultNoMatch;
            }
            NTYTMatchOptions *options = nil;
            if (modifier.matcherExpression.matcher.kind == NTYTMatcherKindPlain) {
                options = [self modifierOptionsForKind:modifier.kind
                                     owningListKind:owningListKind
                                       snapshot:snapshot
                                internalFailure:internalFailure];
                if (*internalFailure || !options) {
                    return NTYTMatchResultNoMatch;
                }
            }
            result = [self evaluateExpression:modifier.matcherExpression
                                    candidate:metadata.title
                                      options:options
                              internalFailure:internalFailure];
            break;
        }
        case NTYTModifierKindVideo:
            if (modifier.matcherExpression) {
                *internalFailure = YES;
                return NTYTMatchResultNoMatch;
            }
            result = metadata.contentType == NTYTContentTypeVideo
                ? NTYTMatchResultMatch
                : NTYTMatchResultNoMatch;
            break;
        default:
            *internalFailure = YES;
            return NTYTMatchResultNoMatch;
    }
    if (*internalFailure) {
        return NTYTMatchResultNoMatch;
    }
    return modifier.isNegative ? NTYTNegateMatchResult(result) : result;
}

+ (nullable NTYTMatchOptions *)modifierOptionsForKind:(NTYTModifierKind)modifierKind
                                   owningListKind:(NTYTListKind)owningListKind
                                     snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot
                              internalFailure:(BOOL *)internalFailure {
    BOOL allowPhase = NO;
    switch (owningListKind) {
        case NTYTListKindBlock:
            allowPhase = NO;
            break;
        case NTYTListKindAllow:
            allowPhase = YES;
            break;
        default:
            *internalFailure = YES;
            return nil;
    }

    NTYTListID optionsListID;
    switch (modifierKind) {
        case NTYTModifierKindChannel:
            optionsListID = allowPhase
                ? NTYTListIDChannelsAllow
                : NTYTListIDChannelsBlock;
            break;
        case NTYTModifierKindContent:
            optionsListID = allowPhase
                ? NTYTListIDGeneralAllow
                : NTYTListIDGeneralBlock;
            break;
        case NTYTModifierKindVideo:
        default:
            *internalFailure = YES;
            return nil;
    }

    NTYTRuntimeListState *state = [snapshot stateForListID:optionsListID];
    if (!state ||
        state.listID != optionsListID ||
        !state.options) {
        *internalFailure = YES;
        return nil;
    }
    return state.options;
}

+ (NTYTMatchResult)evaluateExpression:(NTYTMatcherExpression *)expression
                            candidate:(NSString *)candidate
                              options:(NTYTMatchOptions *)options
                      internalFailure:(BOOL *)internalFailure {
    if (!expression || !expression.matcher) {
        *internalFailure = YES;
        return NTYTMatchResultNoMatch;
    }
    NTYTMatchResult positive =
        [self evaluatePositiveMatcher:expression.matcher
                            candidate:candidate
                              options:options
                      internalFailure:internalFailure];
    if (*internalFailure) {
        return NTYTMatchResultNoMatch;
    }
    return expression.isNegative ? NTYTNegateMatchResult(positive) : positive;
}

+ (NTYTMatchResult)evaluateChannelExpression:(NTYTMatcherExpression *)expression
                                    metadata:(NTYTContentMetadata *)metadata
                                     options:(NTYTMatchOptions *)options
                             internalFailure:(BOOL *)internalFailure {
    if (!expression || !expression.matcher) {
        *internalFailure = YES;
        return NTYTMatchResultNoMatch;
    }

    NSArray *fields = @[
        metadata.channelID ?: [NSNull null],
        metadata.channelName ?: [NSNull null],
        metadata.handle ?: [NSNull null],
    ];
    BOOL hasAvailableField = NO;
    NTYTMatchResult aggregate = NTYTMatchResultNoMatch;
    for (id field in fields) {
        if (field == [NSNull null]) {
            continue;
        }
        hasAvailableField = YES;
        NTYTMatchResult fieldResult =
            [self evaluatePositiveMatcher:expression.matcher
                                candidate:(NSString *)field
                                  options:options
                          internalFailure:internalFailure];
        if (*internalFailure) {
            return NTYTMatchResultNoMatch;
        }
        if (fieldResult == NTYTMatchResultMatch) {
            aggregate = NTYTMatchResultMatch;
            break;
        }
    }
    if (!hasAvailableField) {
        aggregate = NTYTMatchResultUnavailable;
    }
    return expression.isNegative ? NTYTNegateMatchResult(aggregate) : aggregate;
}

+ (NTYTMatchResult)evaluatePositiveMatcher:(NTYTMatcher *)matcher
                                  candidate:(NSString *)candidate
                                    options:(NTYTMatchOptions *)options
                            internalFailure:(BOOL *)internalFailure {
    if (!matcher) {
        *internalFailure = YES;
        return NTYTMatchResultNoMatch;
    }
    if (candidate == nil) {
        return NTYTMatchResultUnavailable;
    }

    switch (matcher.kind) {
        case NTYTMatcherKindPlain: {
            if (matcher.plainText == nil || !options) {
                *internalFailure = YES;
                return NTYTMatchResultNoMatch;
            }
            NSStringCompareOptions compareOptions = NSLiteralSearch;
            if (!options.caseSensitive) {
                compareOptions |= NSCaseInsensitiveSearch;
            }
            BOOL matched = NO;
            if (options.exactMatch) {
                matched = [candidate compare:matcher.plainText
                                     options:compareOptions] == NSOrderedSame;
            } else {
                matched = [candidate rangeOfString:matcher.plainText
                                           options:compareOptions].location != NSNotFound;
            }
            return matched ? NTYTMatchResultMatch : NTYTMatchResultNoMatch;
        }
        case NTYTMatcherKindRegex: {
            if (!matcher.regularExpression) {
                *internalFailure = YES;
                return NTYTMatchResultNoMatch;
            }
            NSRange range = NSMakeRange(0, candidate.length);
            NSTextCheckingResult *match =
                [matcher.regularExpression firstMatchInString:candidate
                                                      options:0
                                                        range:range];
            return match ? NTYTMatchResultMatch : NTYTMatchResultNoMatch;
        }
    }
    *internalFailure = YES;
    return NTYTMatchResultNoMatch;
}

@end
