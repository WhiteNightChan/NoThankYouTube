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
+ (nullable NTYTMetadataValue *)generalTargetForMetadata:(NTYTContentMetadata *)metadata
                                         internalFailure:(BOOL *)internalFailure;
+ (NTYTMatchResult)evaluateExpression:(NTYTMatcherExpression *)expression
                                value:(NTYTMetadataValue *)value
                              options:(nullable NTYTMatchOptions *)options
                      internalFailure:(BOOL *)internalFailure;
+ (NTYTMatchResult)evaluateAggregatedExpression:(NTYTMatcherExpression *)expression
                                          values:(NSArray<NTYTMetadataValue *> *)values
                                         options:(nullable NTYTMatchOptions *)options
                                 internalFailure:(BOOL *)internalFailure;
+ (NTYTMatchResult)evaluatePositiveMatcher:(NTYTMatcher *)matcher
                                      value:(NTYTMetadataValue *)value
                                    options:(nullable NTYTMatchOptions *)options
                            internalFailure:(BOOL *)internalFailure;

@end


@implementation NTYTEvaluator

+ (NTYTDecision)decisionForMetadata:(NTYTContentMetadata *)metadata
                            snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot {
    if (!metadata || !snapshot || metadata.contentType == NTYTContentTypeUnresolved) {
        return NTYTDecisionNoMatch;
    }

    @try {
        if (metadata.contentType == NTYTContentTypePlaylistMix && snapshot.hideMix) {
            return NTYTDecisionBlock;
        }

        BOOL internalFailure = NO;
        NTYTMatchResult allowResult =
            [self evaluatePhaseLists:@[
                @(NTYTListIDGeneralAllow),
                @(NTYTListIDChannelsAllow),
                @(NTYTListIDGlobalAllow),
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
                @(NTYTListIDPostContent),
                @(NTYTListIDPostChannel),
                @(NTYTListIDPlaylistTitle),
                @(NTYTListIDPlaylistChannel),
                @(NTYTListIDPlaylistID),
                @(NTYTListIDGlobalBlock),
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
        NTYTListDefinition *definition = [NTYTListDefinition definitionForListID:listID];
        NTYTRuntimeListState *state = [snapshot stateForListID:listID];
        if (!definition || !state || state.listID != listID || !state.options || !state.rules) {
            *internalFailure = YES;
            return NTYTMatchResultNoMatch;
        }

        if (![definition appliesToContentType:metadata.contentType]) {
            continue;
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
    if (!rule.identifier || !rule.mainMatcher || !rule.modifiers ||
        !definition || !options || !snapshot) {
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
        case NTYTTargetKindGeneral: {
            NTYTMetadataValue *value = [self generalTargetForMetadata:metadata
                                                      internalFailure:internalFailure];
            if (*internalFailure || !value) {
                return NTYTMatchResultNoMatch;
            }
            return [self evaluateExpression:expression value:value options:options
                            internalFailure:internalFailure];
        }
        case NTYTTargetKindTitle:
            return [self evaluateExpression:expression value:metadata.title options:options
                            internalFailure:internalFailure];
        case NTYTTargetKindChannel:
            return [self evaluateAggregatedExpression:expression
                                               values:@[metadata.channelID,
                                                        metadata.channelName,
                                                        metadata.handle]
                                              options:options
                                      internalFailure:internalFailure];
        case NTYTTargetKindVideoID:
            return [self evaluateExpression:expression value:metadata.videoID options:options
                            internalFailure:internalFailure];
        case NTYTTargetKindPostBody:
            return [self evaluateExpression:expression value:metadata.postBody options:options
                            internalFailure:internalFailure];
        case NTYTTargetKindPlaylistID:
            return [self evaluateExpression:expression value:metadata.playlistID options:options
                            internalFailure:internalFailure];
        case NTYTTargetKindGlobal: {
            NTYTMetadataValue *general = [self generalTargetForMetadata:metadata
                                                         internalFailure:internalFailure];
            if (*internalFailure || !general) {
                return NTYTMatchResultNoMatch;
            }
            return [self evaluateAggregatedExpression:expression
                                               values:@[general,
                                                        metadata.channelID,
                                                        metadata.channelName,
                                                        metadata.handle]
                                              options:options
                                      internalFailure:internalFailure];
        }
    }
    *internalFailure = YES;
    return NTYTMatchResultNoMatch;
}

+ (NTYTMatchResult)evaluateModifier:(NTYTModifier *)modifier
                     owningListKind:(NTYTListKind)owningListKind
                           metadata:(NTYTContentMetadata *)metadata
                           snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot
                    internalFailure:(BOOL *)internalFailure {
    if (!modifier) {
        *internalFailure = YES;
        return NTYTMatchResultNoMatch;
    }

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
            result = [self evaluateAggregatedExpression:modifier.matcherExpression
                                                  values:@[metadata.channelID,
                                                           metadata.channelName,
                                                           metadata.handle]
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
            NTYTMetadataValue *general = [self generalTargetForMetadata:metadata
                                                         internalFailure:internalFailure];
            if (*internalFailure || !general) {
                return NTYTMatchResultNoMatch;
            }
            result = [self evaluateExpression:modifier.matcherExpression
                                        value:general
                                      options:options
                              internalFailure:internalFailure];
            break;
        }
        case NTYTModifierKindVideo:
        case NTYTModifierKindPost:
        case NTYTModifierKindPlaylist:
            if (modifier.matcherExpression) {
                *internalFailure = YES;
                return NTYTMatchResultNoMatch;
            }
            if (modifier.kind == NTYTModifierKindVideo) {
                result = metadata.contentType == NTYTContentTypeVideo
                    ? NTYTMatchResultMatch : NTYTMatchResultNoMatch;
            } else if (modifier.kind == NTYTModifierKindPost) {
                result = metadata.contentType == NTYTContentTypePost
                    ? NTYTMatchResultMatch : NTYTMatchResultNoMatch;
            } else {
                BOOL playlist = metadata.contentType == NTYTContentTypePlaylistNormal ||
                                metadata.contentType == NTYTContentTypePlaylistMix;
                result = playlist ? NTYTMatchResultMatch : NTYTMatchResultNoMatch;
            }
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

+ (NTYTMatchOptions *)modifierOptionsForKind:(NTYTModifierKind)modifierKind
                               owningListKind:(NTYTListKind)owningListKind
                                     snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot
                              internalFailure:(BOOL *)internalFailure {
    BOOL allowPhase = NO;
    switch (owningListKind) {
        case NTYTListKindBlock:
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
            optionsListID = allowPhase ? NTYTListIDChannelsAllow : NTYTListIDChannelsBlock;
            break;
        case NTYTModifierKindContent:
            optionsListID = allowPhase ? NTYTListIDGeneralAllow : NTYTListIDGeneralBlock;
            break;
        case NTYTModifierKindVideo:
        case NTYTModifierKindPost:
        case NTYTModifierKindPlaylist:
            *internalFailure = YES;
            return nil;

        default:
            *internalFailure = YES;
            return nil;
    }

    NTYTRuntimeListState *state = [snapshot stateForListID:optionsListID];
    if (!state || state.listID != optionsListID || !state.options) {
        *internalFailure = YES;
        return nil;
    }
    return state.options;
}

+ (NTYTMetadataValue *)generalTargetForMetadata:(NTYTContentMetadata *)metadata
                                internalFailure:(BOOL *)internalFailure {
    switch (metadata.contentType) {
        case NTYTContentTypeVideo:
        case NTYTContentTypePlaylistNormal:
        case NTYTContentTypePlaylistMix:
            return metadata.title;
        case NTYTContentTypePost:
            return metadata.postBody;
        case NTYTContentTypeUnresolved:
            *internalFailure = YES;
            return nil;
    }
    *internalFailure = YES;
    return nil;
}

+ (NTYTMatchResult)evaluateExpression:(NTYTMatcherExpression *)expression
                                value:(NTYTMetadataValue *)value
                              options:(NTYTMatchOptions *)options
                      internalFailure:(BOOL *)internalFailure {
    return [self evaluateAggregatedExpression:expression
                                       values:value ? @[value] : @[]
                                      options:options
                              internalFailure:internalFailure];
}

+ (NTYTMatchResult)evaluateAggregatedExpression:(NTYTMatcherExpression *)expression
                                          values:(NSArray<NTYTMetadataValue *> *)values
                                         options:(NTYTMatchOptions *)options
                                 internalFailure:(BOOL *)internalFailure {
    if (!expression || !expression.matcher || values.count == 0) {
        *internalFailure = YES;
        return NTYTMatchResultNoMatch;
    }

    BOOL sawUnavailable = NO;
    NTYTMatchResult aggregate = NTYTMatchResultNoMatch;
    for (NTYTMetadataValue *value in values) {
        NTYTMatchResult fieldResult = [self evaluatePositiveMatcher:expression.matcher
                                                              value:value
                                                            options:options
                                                    internalFailure:internalFailure];
        if (*internalFailure) {
            return NTYTMatchResultNoMatch;
        }
        if (fieldResult == NTYTMatchResultMatch) {
            aggregate = NTYTMatchResultMatch;
            break;
        }
        if (fieldResult == NTYTMatchResultUnavailable) {
            sawUnavailable = YES;
        }
    }
    if (aggregate != NTYTMatchResultMatch && sawUnavailable) {
        aggregate = NTYTMatchResultUnavailable;
    }
    return expression.isNegative ? NTYTNegateMatchResult(aggregate) : aggregate;
}

+ (NTYTMatchResult)evaluatePositiveMatcher:(NTYTMatcher *)matcher
                                      value:(NTYTMetadataValue *)value
                                    options:(NTYTMatchOptions *)options
                            internalFailure:(BOOL *)internalFailure {
    if (!matcher || !value) {
        *internalFailure = YES;
        return NTYTMatchResultNoMatch;
    }

    switch (value.state) {
        case NTYTMetadataValueStateAbsent:
            return NTYTMatchResultNoMatch;
        case NTYTMetadataValueStateUnavailable:
            return NTYTMatchResultUnavailable;
        case NTYTMetadataValueStateAvailable:
            break;

        default:
            *internalFailure = YES;
            return NTYTMatchResultNoMatch;
    }

    NSString *candidate = value.value;
    if (![candidate isKindOfClass:[NSString class]]) {
        *internalFailure = YES;
        return NTYTMatchResultNoMatch;
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
            BOOL matched = options.exactMatch
                ? [candidate compare:matcher.plainText options:compareOptions] == NSOrderedSame
                : [candidate rangeOfString:matcher.plainText options:compareOptions].location != NSNotFound;
            return matched ? NTYTMatchResultMatch : NTYTMatchResultNoMatch;
        }
        case NTYTMatcherKindRegex: {
            if (!matcher.regularExpression) {
                *internalFailure = YES;
                return NTYTMatchResultNoMatch;
            }
            NSRange range = NSMakeRange(0, candidate.length);
            NSTextCheckingResult *match =
                [matcher.regularExpression firstMatchInString:candidate options:0 range:range];
            return match ? NTYTMatchResultMatch : NTYTMatchResultNoMatch;
        }
    }
    *internalFailure = YES;
    return NTYTMatchResultNoMatch;
}

@end
