#import "NTYTEvaluator.h"

#import "Core/NTYTContentMetadata.h"
#import "Core/NTYTListDefinition.h"
#import "Core/NTYTRuntimeModel.h"
#import "Core/NTYTSemanticQualification.h"

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
+ (nullable NSArray<NTYTMetadataValue *> *)channelValuesForMetadata:(NTYTContentMetadata *)metadata
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

+ (NTYTOptionPhaseOutcome)optionOutcomeForQualification:(NTYTSemanticQualificationResult *)qualification
                                               snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot {
    @try {
        if (![qualification isKindOfClass:[NTYTSemanticQualificationResult class]] ||
            ![snapshot isKindOfClass:[NTYTRuntimeSettingsSnapshot class]] ||
            ![snapshot.blockOptions isKindOfClass:[NTYTBlockOptions class]]) {
            return NTYTOptionPhaseOutcomeInternalFailure;
        }
        // Invalid semantic inputs are internal failure, not target uncertainty.
        if (qualification.contentFamily < NTYTContentFamilyUnresolved ||
            qualification.contentFamily > NTYTContentFamilyPlaylist ||
            qualification.playlistSubtype < NTYTPlaylistSubtypeUnresolved ||
            qualification.playlistSubtype > NTYTPlaylistSubtypeMix ||
            qualification.shortsClassification < NTYTShortsClassificationUnavailable ||
            qualification.shortsClassification > NTYTShortsClassificationNonShorts ||
            qualification.horizontalShelf < NTYTPresentationQualificationUnavailable ||
            qualification.horizontalShelf > NTYTPresentationQualificationConfirmed ||
            qualification.shortsShelf < NTYTPresentationQualificationUnavailable ||
            qualification.shortsShelf > NTYTPresentationQualificationConfirmed ||
            qualification.fromYouTubeCell < NTYTPresentationQualificationUnavailable ||
            qualification.fromYouTubeCell > NTYTPresentationQualificationConfirmed ||
            qualification.adSupportedFreeMovie < NTYTPresentationQualificationUnavailable ||
            qualification.adSupportedFreeMovie > NTYTPresentationQualificationConfirmed ||
            qualification.cellDivider < NTYTPresentationQualificationUnavailable ||
            qualification.cellDivider > NTYTPresentationQualificationConfirmed ||
            qualification.horizontalShelfException < NTYTHorizontalShelfExceptionUnavailable ||
            qualification.horizontalShelfException > NTYTHorizontalShelfExceptionOther ||
            (qualification.horizontalShelf != NTYTPresentationQualificationConfirmed &&
             qualification.horizontalShelfException != NTYTHorizontalShelfExceptionUnavailable) ||
            (qualification.contentFamily != NTYTContentFamilyPlaylist &&
             qualification.playlistSubtype != NTYTPlaylistSubtypeUnresolved) ||
            ((qualification.contentFamily == NTYTContentFamilyPost ||
              qualification.contentFamily == NTYTContentFamilyPlaylist) &&
             qualification.shortsClassification != NTYTShortsClassificationNonShorts) ||
            (qualification.contentFamily == NTYTContentFamilyUnresolved &&
             qualification.shortsClassification != NTYTShortsClassificationUnavailable) ||
            (qualification.fromYouTubeCell == NTYTPresentationQualificationConfirmed &&
             qualification.contentFamily == NTYTContentFamilyVideo &&
             qualification.shortsClassification != NTYTShortsClassificationUnavailable)) {
            return NTYTOptionPhaseOutcomeInternalFailure;
        }

        NTYTBlockOptions *options = snapshot.blockOptions;
        BOOL block =
            (options.blockShorts &&
             (qualification.shortsClassification == NTYTShortsClassificationShorts ||
              qualification.shortsShelf == NTYTPresentationQualificationConfirmed)) ||
            (options.blockPost && qualification.contentFamily == NTYTContentFamilyPost) ||
            (options.blockPlaylist && qualification.contentFamily == NTYTContentFamilyPlaylist) ||
            (options.blockMix && qualification.contentFamily == NTYTContentFamilyPlaylist &&
             qualification.playlistSubtype == NTYTPlaylistSubtypeMix) ||
            (options.blockHorizontalShelf &&
             qualification.horizontalShelf == NTYTPresentationQualificationConfirmed &&
             qualification.horizontalShelfException == NTYTHorizontalShelfExceptionOther) ||
            (options.blockFromYouTube &&
             qualification.fromYouTubeCell == NTYTPresentationQualificationConfirmed) ||
            (options.blockAdSupportedFreeMovie &&
             qualification.adSupportedFreeMovie == NTYTPresentationQualificationConfirmed) ||
            (options.blockCellDivider &&
             qualification.cellDivider == NTYTPresentationQualificationConfirmed);
        return block ? NTYTOptionPhaseOutcomeBlock : NTYTOptionPhaseOutcomeNoBlock;
    } @catch (__unused NSException *exception) {
        return NTYTOptionPhaseOutcomeInternalFailure;
    }
}

+ (NTYTDecision)decisionForMetadata:(NTYTContentMetadata *)metadata
                            snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot {
    if (!metadata || !snapshot || metadata.contentType == NTYTContentTypeUnresolved) {
        return NTYTDecisionNoMatch;
    }

    @try {
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
                @(NTYTListIDPostID),
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
        case NTYTTargetKindChannel: {
            NSArray<NTYTMetadataValue *> *values =
                [self channelValuesForMetadata:metadata internalFailure:internalFailure];
            if (*internalFailure) {
                return NTYTMatchResultNoMatch;
            }
            return [self evaluateAggregatedExpression:expression values:values
                                              options:options internalFailure:internalFailure];
        }
        case NTYTTargetKindVideoID:
            return [self evaluateExpression:expression value:metadata.videoID options:options
                            internalFailure:internalFailure];
        case NTYTTargetKindPostBody:
            return [self evaluateExpression:expression value:metadata.postBody options:options
                            internalFailure:internalFailure];
        case NTYTTargetKindPostID:
            return [self evaluateExpression:expression value:metadata.postID options:options
                            internalFailure:internalFailure];
        case NTYTTargetKindPlaylistID:
            return [self evaluateExpression:expression value:metadata.playlistID options:options
                            internalFailure:internalFailure];
        case NTYTTargetKindGlobal: {
            NTYTMetadataValue *general = [self generalTargetForMetadata:metadata
                                                         internalFailure:internalFailure];
            NSArray<NTYTMetadataValue *> *channelValues =
                [self channelValuesForMetadata:metadata internalFailure:internalFailure];
            if (*internalFailure || !general || !channelValues) {
                return NTYTMatchResultNoMatch;
            }
            NSMutableArray<NTYTMetadataValue *> *values =
                [NSMutableArray arrayWithObject:general];
            [values addObjectsFromArray:channelValues];
            return [self evaluateAggregatedExpression:expression
                                               values:values
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
            NSArray<NTYTMetadataValue *> *values =
                [self channelValuesForMetadata:metadata internalFailure:internalFailure];
            if (*internalFailure) {
                return NTYTMatchResultNoMatch;
            }
            result = [self evaluateAggregatedExpression:modifier.matcherExpression
                                                  values:values
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

        case NTYTModifierKindShorts:
            if (modifier.matcherExpression) {
                *internalFailure = YES;
                return NTYTMatchResultNoMatch;
            }
            switch (metadata.shortsClassification) {
                case NTYTShortsClassificationShorts:
                    result = NTYTMatchResultMatch;
                    break;
                case NTYTShortsClassificationNonShorts:
                    result = NTYTMatchResultNoMatch;
                    break;
                case NTYTShortsClassificationUnavailable:
                    result = NTYTMatchResultUnavailable;
                    break;
                default:
                    *internalFailure = YES;
                    return NTYTMatchResultNoMatch;
            }
            break;

        case NTYTModifierKindUpcoming:
        case NTYTModifierKindCurrent: {
            if (modifier.matcherExpression) {
                *internalFailure = YES;
                return NTYTMatchResultNoMatch;
            }
            if (metadata.contentType != NTYTContentTypeVideo) {
                result = NTYTMatchResultNoMatch;
                break;
            }
            NTYTTemporalClassification classification =
                modifier.kind == NTYTModifierKindUpcoming
                    ? metadata.upcomingClassification : metadata.currentClassification;
            switch (classification) {
                case NTYTTemporalClassificationConfirmed:
                    result = NTYTMatchResultMatch;
                    break;
                case NTYTTemporalClassificationNotConfirmed:
                    result = NTYTMatchResultNoMatch;
                    break;
                case NTYTTemporalClassificationUnavailable:
                    result = NTYTMatchResultUnavailable;
                    break;
                default:
                    *internalFailure = YES;
                    return NTYTMatchResultNoMatch;
            }
            break;
        }

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
        case NTYTModifierKindShorts:
        case NTYTModifierKindUpcoming:
        case NTYTModifierKindCurrent:
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

+ (nullable NSArray<NTYTMetadataValue *> *)channelValuesForMetadata:(NTYTContentMetadata *)metadata
                                             internalFailure:(BOOL *)internalFailure {
    NTYTChannelIdentityCollection *collection = metadata.channelIdentityCollection;
    if (!collection) {
        *internalFailure = YES;
        return nil;
    }
    switch (collection.state) {
        case NTYTChannelIdentityCollectionStateUnavailable:
            if (collection.identities.count != 0) {
                *internalFailure = YES;
                return nil;
            }
            return @[[NTYTMetadataValue unavailableValue]];

        case NTYTChannelIdentityCollectionStateAvailable: {
            if (collection.identities.count == 0) {
                *internalFailure = YES;
                return nil;
            }
            NSMutableArray<NTYTMetadataValue *> *values =
                [NSMutableArray arrayWithCapacity:collection.identities.count * 3];
            for (NTYTChannelIdentity *identity in collection.identities) {
                if (!identity.channelID || !identity.channelName || !identity.handle) {
                    *internalFailure = YES;
                    return nil;
                }
                [values addObjectsFromArray:@[identity.channelID,
                                               identity.channelName,
                                               identity.handle]];
            }
            return values;
        }
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

    BOOL sawNoMatch = NO;
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
        if (fieldResult == NTYTMatchResultNoMatch) {
            sawNoMatch = YES;
        } else if (fieldResult == NTYTMatchResultUnavailable) {
            sawUnavailable = YES;
        }
    }
    if (aggregate != NTYTMatchResultMatch) {
        aggregate = sawNoMatch
            ? NTYTMatchResultNoMatch
            : (sawUnavailable ? NTYTMatchResultUnavailable : NTYTMatchResultNoMatch);
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
