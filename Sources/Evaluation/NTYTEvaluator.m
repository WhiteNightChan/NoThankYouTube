#import "NTYTEvaluator.h"

#import "Core/NTYTContentMetadata.h"
#import "Core/NTYTListDefinition.h"
#import "Core/NTYTRuntimeModel.h"
#import "Core/NTYTSemanticQualification.h"

@interface NTYTEvaluator ()

+ (NTYTMatchResult)evaluatePhaseListSequence:(NSArray<NSNumber *> *)listIDs
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
                        matchOptionState:(NTYTMatchOptionState *)matchOptionState
                       metadata:(NTYTContentMetadata *)metadata
                       snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot
                internalFailure:(BOOL *)internalFailure;
+ (NTYTMatchResult)evaluateMainExpression:(NTYTMatcherExpression *)expression
                               targetKind:(NTYTTargetKind)targetKind
                                  matchOptionState:(NTYTMatchOptionState *)matchOptionState
                                 metadata:(NTYTContentMetadata *)metadata
                          internalFailure:(BOOL *)internalFailure;
+ (NTYTMatchResult)evaluateModifier:(NTYTModifier *)modifier
                     owningListKind:(NTYTListKind)owningListKind
                           metadata:(NTYTContentMetadata *)metadata
                           snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot
                    internalFailure:(BOOL *)internalFailure;
+ (nullable NTYTMatchOptionState *)modifierMatchOptionStateForKind:(NTYTModifierKind)modifierKind
                                        owningListKind:(NTYTListKind)owningListKind
                                              snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot
                                       internalFailure:(BOOL *)internalFailure;
+ (nullable NTYTMetadataValue *)generalTargetForMetadata:(NTYTContentMetadata *)metadata
                                         internalFailure:(BOOL *)internalFailure;
+ (nullable NSArray<NTYTMetadataValue *> *)channelValuesForMetadata:(NTYTContentMetadata *)metadata
                                                       internalFailure:(BOOL *)internalFailure;
+ (NTYTMatchResult)evaluateExpression:(NTYTMatcherExpression *)expression
                                value:(NTYTMetadataValue *)value
                              matchOptionState:(nullable NTYTMatchOptionState *)matchOptionState
                      internalFailure:(BOOL *)internalFailure;
+ (NTYTMatchResult)evaluateAggregatedExpression:(NTYTMatcherExpression *)expression
                                          values:(NSArray<NTYTMetadataValue *> *)values
                                         matchOptionState:(nullable NTYTMatchOptionState *)matchOptionState
                                 internalFailure:(BOOL *)internalFailure;
+ (NTYTMatchResult)evaluatePositiveMatcher:(NTYTMatcher *)matcher
                                      value:(NTYTMetadataValue *)value
                                    matchOptionState:(nullable NTYTMatchOptionState *)matchOptionState
                            internalFailure:(BOOL *)internalFailure;

@end


@implementation NTYTEvaluator

+ (NTYTOptionPhaseOutcome)optionOutcomeForQualification:(NTYTSemanticQualificationResult *)qualification
                                               snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot {
    @try {
        if (![qualification isKindOfClass:[NTYTSemanticQualificationResult class]] ||
            ![snapshot isKindOfClass:[NTYTRuntimeSettingsSnapshot class]] ||
            ![snapshot.blockOptionState isKindOfClass:[NTYTBlockOptionState class]]) {
            return NTYTOptionPhaseOutcomeInternalFailure;
        }
        // Invalid semantic inputs are internal failure, not target uncertainty.
        if ((qualification.contentFamily != NTYTContentFamilyUnresolved &&
             qualification.contentFamily != NTYTContentFamilyVideo &&
             qualification.contentFamily != NTYTContentFamilyPost &&
             qualification.contentFamily != NTYTContentFamilyPlaylist) ||
            (qualification.playlistSubtype != NTYTPlaylistSubtypeUnresolved &&
             qualification.playlistSubtype != NTYTPlaylistSubtypeNormal &&
             qualification.playlistSubtype != NTYTPlaylistSubtypeMix) ||
            (qualification.shortsClassification != NTYTShortsClassificationNonShorts &&
             qualification.shortsClassification != NTYTShortsClassificationShorts &&
             qualification.shortsClassification != NTYTShortsClassificationUnavailable) ||
            (qualification.stationClassification != NTYTStationClassificationNonStation &&
             qualification.stationClassification != NTYTStationClassificationStation &&
             qualification.stationClassification != NTYTStationClassificationUnavailable) ||
            (qualification.horizontalShelf != NTYTPresentationQualificationNotConfirmed &&
             qualification.horizontalShelf != NTYTPresentationQualificationConfirmed &&
             qualification.horizontalShelf != NTYTPresentationQualificationUnavailable) ||
            (qualification.shortsShelf != NTYTPresentationQualificationNotConfirmed &&
             qualification.shortsShelf != NTYTPresentationQualificationConfirmed &&
             qualification.shortsShelf != NTYTPresentationQualificationUnavailable) ||
            (qualification.fromYouTubeCell != NTYTPresentationQualificationNotConfirmed &&
             qualification.fromYouTubeCell != NTYTPresentationQualificationConfirmed &&
             qualification.fromYouTubeCell != NTYTPresentationQualificationUnavailable) ||
            (qualification.adSupportedFreeMovie != NTYTPresentationQualificationNotConfirmed &&
             qualification.adSupportedFreeMovie != NTYTPresentationQualificationConfirmed &&
             qualification.adSupportedFreeMovie != NTYTPresentationQualificationUnavailable) ||
            (qualification.cellDivider != NTYTPresentationQualificationNotConfirmed &&
             qualification.cellDivider != NTYTPresentationQualificationConfirmed &&
             qualification.cellDivider != NTYTPresentationQualificationUnavailable) ||
            (qualification.horizontalShelfException != NTYTHorizontalShelfExceptionUnavailable &&
             qualification.horizontalShelfException != NTYTHorizontalShelfExceptionHistory &&
             qualification.horizontalShelfException != NTYTHorizontalShelfExceptionPlaylist &&
             qualification.horizontalShelfException != NTYTHorizontalShelfExceptionOther) ||
            (qualification.horizontalShelf != NTYTPresentationQualificationConfirmed &&
             qualification.horizontalShelfException != NTYTHorizontalShelfExceptionUnavailable) ||
            (qualification.contentFamily != NTYTContentFamilyPlaylist &&
             qualification.playlistSubtype != NTYTPlaylistSubtypeUnresolved) ||
            ((qualification.contentFamily == NTYTContentFamilyPost ||
              qualification.contentFamily == NTYTContentFamilyPlaylist) &&
             qualification.shortsClassification != NTYTShortsClassificationNonShorts) ||
            (qualification.contentFamily == NTYTContentFamilyUnresolved &&
             qualification.shortsClassification != NTYTShortsClassificationUnavailable) ||
            ((qualification.contentFamily == NTYTContentFamilyPost ||
              qualification.contentFamily == NTYTContentFamilyPlaylist) &&
             qualification.stationClassification != NTYTStationClassificationNonStation) ||
            (qualification.contentFamily == NTYTContentFamilyUnresolved &&
             qualification.stationClassification != NTYTStationClassificationUnavailable) ||
            (qualification.fromYouTubeCell == NTYTPresentationQualificationConfirmed &&
             qualification.contentFamily == NTYTContentFamilyVideo &&
             qualification.shortsClassification != NTYTShortsClassificationUnavailable)) {
            return NTYTOptionPhaseOutcomeInternalFailure;
        }

        NTYTBlockOptionState *blockOptionState = snapshot.blockOptionState;
        BOOL block =
            (blockOptionState.blockShorts &&
             (qualification.shortsClassification == NTYTShortsClassificationShorts ||
              qualification.shortsShelf == NTYTPresentationQualificationConfirmed)) ||
            (blockOptionState.blockPost && qualification.contentFamily == NTYTContentFamilyPost) ||
            (blockOptionState.blockPlaylist && qualification.contentFamily == NTYTContentFamilyPlaylist) ||
            (blockOptionState.blockMix && qualification.contentFamily == NTYTContentFamilyPlaylist &&
             qualification.playlistSubtype == NTYTPlaylistSubtypeMix) ||
            (blockOptionState.blockHorizontalShelf &&
             qualification.horizontalShelf == NTYTPresentationQualificationConfirmed &&
             qualification.horizontalShelfException == NTYTHorizontalShelfExceptionOther) ||
            (blockOptionState.blockFromYouTube &&
             qualification.fromYouTubeCell == NTYTPresentationQualificationConfirmed) ||
            (blockOptionState.blockAdSupportedFreeMovie &&
             qualification.adSupportedFreeMovie == NTYTPresentationQualificationConfirmed) ||
            (blockOptionState.blockCellDivider &&
             qualification.cellDivider == NTYTPresentationQualificationConfirmed) ||
            (blockOptionState.blockStation && qualification.stationClassification == NTYTStationClassificationStation);
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
            [self evaluatePhaseListSequence:@[
                @(NTYTListIDGeneralAllow),
                @(NTYTListIDChannelAllow),
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
            [self evaluatePhaseListSequence:@[
                @(NTYTListIDGeneralBlock),
                @(NTYTListIDVideoTitle),
                @(NTYTListIDVideoChannel),
                @(NTYTListIDVideoID),
                @(NTYTListIDChannelBlock),
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

+ (NTYTMatchResult)evaluatePhaseListSequence:(NSArray<NSNumber *> *)listIDs
                              metadata:(NTYTContentMetadata *)metadata
                              snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot
                       internalFailure:(BOOL *)internalFailure {
    BOOL sawUnavailable = NO;
    for (NSNumber *listNumber in listIDs) {
        NTYTListID listID = (NTYTListID)listNumber.integerValue;
        NTYTListDefinition *definition = [NTYTListDefinition definitionForListID:listID];
        NTYTRuntimeListState *state = [snapshot stateForListID:listID];
        if (!definition || !state || state.listID != listID || !state.matchOptionState || !state.ruleSequence) {
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
    for (NTYTRuntimeRule *rule in listState.ruleSequence) {
        NTYTMatchResult result = [self evaluateRule:rule
                                         definition:definition
                                            matchOptionState:listState.matchOptionState
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
                        matchOptionState:(NTYTMatchOptionState *)matchOptionState
                       metadata:(NTYTContentMetadata *)metadata
                       snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot
                internalFailure:(BOOL *)internalFailure {
    if (!rule.identifier || !rule.mainMatcher || !rule.modifiers ||
        !definition || !matchOptionState || !snapshot) {
        *internalFailure = YES;
        return NTYTMatchResultNoMatch;
    }

    BOOL sawUnavailable = NO;
    NTYTMatchResult mainResult =
        [self evaluateMainExpression:rule.mainMatcher
                          targetKind:definition.targetKind
                             matchOptionState:matchOptionState
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
                                  matchOptionState:(NTYTMatchOptionState *)matchOptionState
                                 metadata:(NTYTContentMetadata *)metadata
                          internalFailure:(BOOL *)internalFailure {
    switch (targetKind) {
        case NTYTTargetKindGeneral: {
            NTYTMetadataValue *value = [self generalTargetForMetadata:metadata
                                                      internalFailure:internalFailure];
            if (*internalFailure || !value) {
                return NTYTMatchResultNoMatch;
            }
            return [self evaluateExpression:expression value:value matchOptionState:matchOptionState
                            internalFailure:internalFailure];
        }
        case NTYTTargetKindTitle:
            return [self evaluateExpression:expression value:metadata.title matchOptionState:matchOptionState
                            internalFailure:internalFailure];
        case NTYTTargetKindChannel: {
            NSArray<NTYTMetadataValue *> *values =
                [self channelValuesForMetadata:metadata internalFailure:internalFailure];
            if (*internalFailure) {
                return NTYTMatchResultNoMatch;
            }
            return [self evaluateAggregatedExpression:expression values:values
                                              matchOptionState:matchOptionState internalFailure:internalFailure];
        }
        case NTYTTargetKindVideoID:
            return [self evaluateExpression:expression value:metadata.videoID matchOptionState:matchOptionState
                            internalFailure:internalFailure];
        case NTYTTargetKindPostBody:
            return [self evaluateExpression:expression value:metadata.postBody matchOptionState:matchOptionState
                            internalFailure:internalFailure];
        case NTYTTargetKindPostID:
            return [self evaluateExpression:expression value:metadata.postID matchOptionState:matchOptionState
                            internalFailure:internalFailure];
        case NTYTTargetKindPlaylistID:
            return [self evaluateExpression:expression value:metadata.playlistID matchOptionState:matchOptionState
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
                                              matchOptionState:matchOptionState
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
            NTYTMatchOptionState *matchOptionState = nil;
            if (modifier.matcherExpression.matcher.kind == NTYTMatcherKindPlain) {
                matchOptionState = [self modifierMatchOptionStateForKind:modifier.kind
                                       owningListKind:owningListKind
                                             snapshot:snapshot
                                      internalFailure:internalFailure];
                if (*internalFailure || !matchOptionState) {
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
                                                 matchOptionState:matchOptionState
                                         internalFailure:internalFailure];
            break;
        }
        case NTYTModifierKindContent: {
            if (!modifier.matcherExpression) {
                *internalFailure = YES;
                return NTYTMatchResultNoMatch;
            }
            NTYTMatchOptionState *matchOptionState = nil;
            if (modifier.matcherExpression.matcher.kind == NTYTMatcherKindPlain) {
                matchOptionState = [self modifierMatchOptionStateForKind:modifier.kind
                                       owningListKind:owningListKind
                                             snapshot:snapshot
                                      internalFailure:internalFailure];
                if (*internalFailure || !matchOptionState) {
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
                                      matchOptionState:matchOptionState
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

        case NTYTModifierKindStation:
            if (modifier.matcherExpression) {
                *internalFailure = YES;
                return NTYTMatchResultNoMatch;
            }
            switch (metadata.stationClassification) {
                case NTYTStationClassificationStation:
                    result = NTYTMatchResultMatch;
                    break;
                case NTYTStationClassificationNonStation:
                    result = NTYTMatchResultNoMatch;
                    break;
                case NTYTStationClassificationUnavailable:
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

+ (NTYTMatchOptionState *)modifierMatchOptionStateForKind:(NTYTModifierKind)modifierKind
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

    NTYTListID optionSourceListID;
    switch (modifierKind) {
        case NTYTModifierKindChannel:
            optionSourceListID = allowPhase ? NTYTListIDChannelAllow : NTYTListIDChannelBlock;
            break;
        case NTYTModifierKindContent:
            optionSourceListID = allowPhase ? NTYTListIDGeneralAllow : NTYTListIDGeneralBlock;
            break;
        case NTYTModifierKindVideo:
        case NTYTModifierKindPost:
        case NTYTModifierKindPlaylist:
        case NTYTModifierKindShorts:
        case NTYTModifierKindStation:
        case NTYTModifierKindUpcoming:
        case NTYTModifierKindCurrent:
            *internalFailure = YES;
            return nil;

        default:
            *internalFailure = YES;
            return nil;
    }

    NTYTRuntimeListState *state = [snapshot stateForListID:optionSourceListID];
    if (!state || state.listID != optionSourceListID || !state.matchOptionState) {
        *internalFailure = YES;
        return nil;
    }
    return state.matchOptionState;
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
                              matchOptionState:(NTYTMatchOptionState *)matchOptionState
                      internalFailure:(BOOL *)internalFailure {
    return [self evaluateAggregatedExpression:expression
                                       values:value ? @[value] : @[]
                                      matchOptionState:matchOptionState
                              internalFailure:internalFailure];
}

+ (NTYTMatchResult)evaluateAggregatedExpression:(NTYTMatcherExpression *)expression
                                          values:(NSArray<NTYTMetadataValue *> *)values
                                         matchOptionState:(NTYTMatchOptionState *)matchOptionState
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
                                                            matchOptionState:matchOptionState
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
                                    matchOptionState:(NTYTMatchOptionState *)matchOptionState
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
            if (matcher.plainText == nil || !matchOptionState) {
                *internalFailure = YES;
                return NTYTMatchResultNoMatch;
            }
            NSStringCompareOptions compareOptions = NSLiteralSearch;
            if (!matchOptionState.caseSensitive) {
                compareOptions |= NSCaseInsensitiveSearch;
            }
            BOOL matched = matchOptionState.exactMatch
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
