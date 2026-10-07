#import "NTYTProductionFilter.h"

#import <YouTubeHeader/YTIElementRenderer.h>

#import "Core/NTYTContentMetadata.h"
#import "Core/NTYTRuntimeModel.h"
#import "Core/NTYTSemanticQualification.h"
#import "Evaluation/NTYTEvaluator.h"
#import "Extraction/NTYTMetadataExtractor.h"
#import "NTYTContentQualifier.h"
#import "Debug/LogHelper.h"

@interface NSObject (NTYTElementRendererAccess)
- (nullable id)elementRenderer;
@end

static NSString *NTYTMetadataLogValue(NTYTMetadataValue *metadataValue) {
    switch (metadataValue.state) {
        case NTYTMetadataValueStateAvailable:
            return metadataValue.value ?: @"<available:nil>";
        case NTYTMetadataValueStateAbsent:
            return @"<absent>";
        case NTYTMetadataValueStateUnavailable:
            return @"<unavailable>";
    }
    return @"<invalid>";
}

static NSString *NTYTChannelCollectionLogValue(NTYTChannelIdentityCollection *collection) {
    if (collection.state == NTYTChannelIdentityCollectionStateUnavailable) {
        return @"<unavailable>";
    }
    NSMutableArray<NSString *> *entries = [NSMutableArray array];
    for (NTYTChannelIdentity *identity in collection.identities) {
        [entries addObject:[NSString stringWithFormat:@"{%@ | %@ | %@}",
                            NTYTMetadataLogValue(identity.channelID),
                            NTYTMetadataLogValue(identity.channelName),
                            NTYTMetadataLogValue(identity.handle)]];
    }
    return [entries componentsJoinedByString:@", "];
}

@implementation NTYTProductionFilter

+ (nullable YTIElementRenderer *)elementRendererFromContentEntry:(id)entry {
    if (![entry respondsToSelector:@selector(elementRenderer)]) {
        NTYTLog(@"[FilterDiag] keep child: wrapper=%@ has no elementRenderer",
                entry ? NSStringFromClass([entry class]) : @"<nil>");
        return nil;
    }

    id element = [entry elementRenderer];
    Class elementClass = NSClassFromString(@"YTIElementRenderer");
    if (!elementClass || ![element isKindOfClass:elementClass]) {
        NTYTLog(@"[FilterDiag] keep child: element=%@ expected=YTIElementRenderer",
                element ? NSStringFromClass([element class]) : @"<nil>");
        return nil;
    }

    return (YTIElementRenderer *)element;
}

+ (NTYTDecision)decisionForResolvedElement:(YTIElementRenderer *)element
                                  snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot
                  standaloneHorizontalOnly:(BOOL)standaloneOnly
                                childIndex:(NSUInteger)childIndex {
    NTYTElementQualification *qualification = standaloneOnly
        ? [NTYTContentQualifier qualificationForStandaloneHorizontalElementRenderer:element]
        : [NTYTContentQualifier qualificationForElementRenderer:element];
    NTYTOptionPhaseOutcome outcome = [NTYTEvaluator
        optionOutcomeForQualification:qualification.semanticResult snapshot:snapshot];
    if (outcome == NTYTOptionPhaseOutcomeBlock) return NTYTDecisionBlock;
    if (outcome == NTYTOptionPhaseOutcomeInternalFailure) return NTYTDecisionNoMatch;
    if (outcome != NTYTOptionPhaseOutcomeNoBlock) return NTYTDecisionNoMatch;

    // This route owns only the standalone Horizontal Shelf Option, never Rule filtering.
    if (standaloneOnly) return NTYTDecisionNoMatch;
    if (qualification.semanticResult.projectedContentType == NTYTContentTypeUnresolved) {
        NTYTLog(@"[FilterDiag] keep child=%lu: content projection unresolved after Option phase",
                (unsigned long)childIndex);
        return NTYTDecisionNoMatch;
    }

    NTYTMetadataExtractionResult *extraction =
        [NTYTMetadataExtractor extractFromQualifiedElement:qualification];
    if (!extraction.isSuccess || !extraction.metadata) {
        NTYTLog(@"[Filter] child=%lu extraction failure: %@", (unsigned long)childIndex,
                extraction.error.localizedDescription ?: @"<unknown>");
        return NTYTDecisionNoMatch;
    }
    NTYTContentMetadata *metadata = extraction.metadata;
    NTYTDecision decision = [NTYTEvaluator decisionForMetadata:metadata snapshot:snapshot];
    NTYTLog(@"[Filter] child=%lu type=%ld shortsClassification=%ld videoID=%@ title=%@ postBody=%@ playlistID=%@ channels=[%@] decision=%ld",
            (unsigned long)childIndex, (long)metadata.contentType, (long)metadata.shortsClassification,
            NTYTMetadataLogValue(metadata.videoID), NTYTMetadataLogValue(metadata.title),
            NTYTMetadataLogValue(metadata.postBody), NTYTMetadataLogValue(metadata.playlistID),
            NTYTChannelCollectionLogValue(metadata.channelIdentityCollection), (long)decision);
    return decision;
}

+ (BOOL)shouldRemoveContentEntry:(id)entry
                        snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot
                      childIndex:(NSUInteger)childIndex {
    @try {
        YTIElementRenderer *element = [self elementRendererFromContentEntry:entry];
        if (!element) return NO;
        return [self decisionForResolvedElement:element snapshot:snapshot
                       standaloneHorizontalOnly:NO childIndex:childIndex] == NTYTDecisionBlock;
    } @catch (NSException *exception) {
        NTYTLog(@"[Filter] child=%lu fail-open: %@", (unsigned long)childIndex,
                exception.reason ?: @"<unknown>");
        return NO;
    }
}

+ (BOOL)shouldRemoveStandaloneHorizontalElement:(id)element
                                        snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot {
    @try {
        Class elementClass = NSClassFromString(@"YTIElementRenderer");
        if (!elementClass || ![element isKindOfClass:elementClass]) return NO;
        return [self decisionForResolvedElement:(YTIElementRenderer *)element snapshot:snapshot
                       standaloneHorizontalOnly:YES childIndex:0] == NTYTDecisionBlock;
    } @catch (__unused NSException *exception) {
        return NO;
    }
}

+ (BOOL)shouldRemoveHorizontalListItems:(NSArray *)items
                               snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot {
    @try {
        NTYTSemanticQualificationResult *qualification =
            [NTYTContentQualifier qualificationForHorizontalListItems:items];
        NTYTOptionPhaseOutcome outcome =
            [NTYTEvaluator optionOutcomeForQualification:qualification snapshot:snapshot];
        // InternalFailure aborts here; no lower phase exists for the whole Shelf unit.
        return outcome == NTYTOptionPhaseOutcomeBlock;
    } @catch (__unused NSException *exception) {
        return NO;
    }
}

@end
