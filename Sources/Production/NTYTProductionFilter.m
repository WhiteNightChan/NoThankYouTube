#import "NTYTProductionFilter.h"

#import <YouTubeHeader/YTIElementRenderer.h>

#import "Core/NTYTContentMetadata.h"
#import "Core/NTYTRuntimeModel.h"
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

+ (BOOL)shouldRemoveContentEntry:(id)entry
                        snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot
                      childIndex:(NSUInteger)childIndex {
    @try {
        YTIElementRenderer *element = [self elementRendererFromContentEntry:entry];
        if (!element) {
            return NO;
        }

        NTYTContentType contentType =
            [NTYTContentQualifier qualifiedContentTypeForElementRenderer:element];
        if (contentType == NTYTContentTypeUnresolved) {
            NTYTLog(@"[FilterDiag] keep child=%lu: qualification unresolved",
                    (unsigned long)childIndex);
            return NO;
        }

        NTYTMetadataExtractionResult *extraction =
            [NTYTMetadataExtractor extractFromElementRenderer:element
                                         qualifiedContentType:contentType];

        if (!extraction.isSuccess || !extraction.metadata) {
            NTYTLog(@"[Filter] child=%lu extraction failure: %@",
                    (unsigned long)childIndex,
                    extraction.error.localizedDescription ?: @"<unknown>");
            return NO;
        }

        NTYTContentMetadata *metadata = extraction.metadata;
        NTYTDecision decision =
            [NTYTEvaluator decisionForMetadata:metadata snapshot:snapshot];

        NTYTLog(@"[Filter] child=%lu type=%ld videoID=%@ title=%@ postBody=%@ playlistID=%@ channelID=%@ channelName=%@ handle=%@ decision=%ld",
                (unsigned long)childIndex,
                (long)metadata.contentType,
                NTYTMetadataLogValue(metadata.videoID),
                NTYTMetadataLogValue(metadata.title),
                NTYTMetadataLogValue(metadata.postBody),
                NTYTMetadataLogValue(metadata.playlistID),
                NTYTMetadataLogValue(metadata.channelID),
                NTYTMetadataLogValue(metadata.channelName),
                NTYTMetadataLogValue(metadata.handle),
                (long)decision);

        return decision == NTYTDecisionBlock;
    } @catch (NSException *childException) {
        NTYTLog(@"[Filter] child=%lu fail-open: %@",
                (unsigned long)childIndex,
                childException.reason ?: @"<unknown>");
        return NO;
    }
}

@end
