#import "NTYTProductionFilter.h"

#import <YouTubeHeader/YTIElementRenderer.h>
#import <YouTubeHeader/YTISectionListRenderer.h>

#import "Core/NTYTContentMetadata.h"
#import "Core/NTYTRuntimeModel.h"
#import "Core/NTYTSnapshotHolder.h"
#import "Evaluation/NTYTEvaluator.h"
#import "Extraction/NTYTMetadataExtractor.h"
#import "NTYTContentQualifier.h"
#import "Debug/LogHelper.h"

@interface NSObject (NTYTElementRendererAccess)
- (nullable id)elementRenderer;
@end

@interface YTIItemSectionRenderer (NTYTProductionContentsMutation)
- (nullable id)copyWithZone:(nullable NSZone *)zone;
- (void)setContentsArray:(NSMutableArray *)contentsArray;
@end

static const BOOL NTYTEmptySectionCollectionSafetyVerified = NO;

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

+ (BOOL)contentsArray:(NSArray *)actual
matchesRetainedChildren:(NSArray *)expected {
    if (actual.count != expected.count) {
        return NO;
    }

    for (NSUInteger index = 0; index < expected.count; index++) {
        if ([actual objectAtIndex:index] != [expected objectAtIndex:index]) {
            return NO;
        }
    }

    return YES;
}

+ (nullable YTIItemSectionRenderer *)copiedSectionFromSection:(YTIItemSectionRenderer *)section
                                             retainedChildren:(NSMutableArray *)retainedChildren
                                             originalContents:(NSArray *)originalContents
                                     originalChildrenSnapshot:(NSArray *)originalChildrenSnapshot {
    if (![section respondsToSelector:@selector(copyWithZone:)] ||
        ![section respondsToSelector:@selector(setContentsArray:)]) {
        NTYTLog(@"[Filter] section copy fail-open: copy/setter capability unavailable");
        return nil;
    }

    id copiedValue = [section copyWithZone:nil];
    Class sectionClass = NSClassFromString(@"YTIItemSectionRenderer");
    if (!copiedValue || copiedValue == section ||
        !sectionClass || ![copiedValue isKindOfClass:sectionClass]) {
        NTYTLog(@"[Filter] section copy fail-open: invalid copy class=%@ sameObject=%@",
                copiedValue ? NSStringFromClass([copiedValue class]) : @"<nil>",
                copiedValue == section ? @"YES" : @"NO");
        return nil;
    }

    YTIItemSectionRenderer *copiedSection =
        (YTIItemSectionRenderer *)copiedValue;

    if (![copiedSection respondsToSelector:@selector(setContentsArray:)]) {
        NTYTLog(@"[Filter] section copy fail-open: copied section setter unavailable");
        return nil;
    }

    [copiedSection setContentsArray:retainedChildren];

    id originalContentsAfterCommit = [section contentsArray];
    id committedContentsValue = [copiedSection contentsArray];
    if (originalContentsAfterCommit != originalContents ||
        ![originalContentsAfterCommit isKindOfClass:[NSArray class]] ||
        ![self contentsArray:(NSArray *)originalContentsAfterCommit
      matchesRetainedChildren:originalChildrenSnapshot] ||
        retainedChildren == originalContents ||
        ![committedContentsValue isKindOfClass:[NSArray class]] ||
        committedContentsValue == originalContents ||
        ![self contentsArray:(NSArray *)committedContentsValue
      matchesRetainedChildren:retainedChildren]) {
        NTYTLog(@"[Filter] section copy fail-open: replacement postcondition failed");
        return nil;
    }

    return copiedSection;
}

+ (nullable YTIItemSectionRenderer *)filteredSectionFromSection:(YTIItemSectionRenderer *)section
                                                       snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot {
    id contentsValue = [section contentsArray];
    if (![contentsValue isKindOfClass:[NSArray class]]) {
        NTYTLog(@"[FilterDiag] keep section: contentsArray class=%@",
                contentsValue ? NSStringFromClass([contentsValue class]) : @"<nil>");
        return section;
    }

    NSArray *contents = (NSArray *)contentsValue;
    if (contents.count == 0) {
        NTYTLog(@"[FilterDiag] keep section: contentsArray.count=0");
        return section;
    }

    NSMutableArray *retainedChildren =
        [NSMutableArray arrayWithCapacity:contents.count];
    NSArray *originalChildrenSnapshot = [contents copy];
    BOOL removedAnyChild = NO;
    NSUInteger childIndex = 0;

    for (id entry in contents) {
        BOOL removeChild =
            [self shouldRemoveContentEntry:entry
                                  snapshot:snapshot
                                childIndex:childIndex];

        if (removeChild) {
            removedAnyChild = YES;
        } else {
            [retainedChildren addObject:entry];
        }

        childIndex++;
    }

    if (!removedAnyChild) {
        return section;
    }

    if (retainedChildren.count == 0) {
        NTYTLog(@"[Filter] remove section: all %lu children blocked",
                (unsigned long)contents.count);
        return nil;
    }

    YTIItemSectionRenderer *copiedSection =
        [self copiedSectionFromSection:section
                      retainedChildren:retainedChildren
                      originalContents:contents
              originalChildrenSnapshot:originalChildrenSnapshot];

    if (!copiedSection) {
        return section;
    }

    NTYTLog(@"[Filter] partial section commit: inputChildren=%lu retainedChildren=%lu",
            (unsigned long)contents.count,
            (unsigned long)retainedChildren.count);

    return copiedSection;
}

+ (NSArray *)filteredSectionCollectionFromOriginal:(NSArray *)originalCollection {
    if (![originalCollection isKindOfClass:[NSArray class]] || originalCollection.count == 0) {
        return originalCollection;
    }

    @try {
        NTYTRuntimeSettingsSnapshot *snapshot =
            [[NTYTSnapshotHolder sharedHolder] currentSnapshot];
        if (!snapshot) {
            return originalCollection;
        }

        Class sectionClass = NSClassFromString(@"YTIItemSectionRenderer");
        if (!sectionClass) {
            return originalCollection;
        }

        NSMutableArray *filtered =
            [NSMutableArray arrayWithCapacity:originalCollection.count];
        BOOL changedAnySection = NO;

        for (id candidate in originalCollection) {
            id resultCandidate = candidate;
            BOOL removeCandidate = NO;

            if ([candidate isKindOfClass:sectionClass]) {
                @try {
                    YTIItemSectionRenderer *sectionResult =
                        [self filteredSectionFromSection:(YTIItemSectionRenderer *)candidate
                                                 snapshot:snapshot];

                    if (!sectionResult) {
                        removeCandidate = YES;
                        changedAnySection = YES;
                    } else {
                        resultCandidate = sectionResult;
                        if (sectionResult != candidate) {
                            changedAnySection = YES;
                        }
                    }
                } @catch (NSException *sectionException) {
                    NTYTLog(@"[Filter] section fail-open: %@",
                            sectionException.reason ?: @"<unknown>");
                    resultCandidate = candidate;
                    removeCandidate = NO;
                }
            }

            if (!removeCandidate) {
                [filtered addObject:resultCandidate];
            }
        }

        if (!changedAnySection) {
            return originalCollection;
        }

        if (filtered.count == 0 && !NTYTEmptySectionCollectionSafetyVerified) {
            NTYTLog(@"[Filter] fail-open: filtered outer result would be empty");
            return originalCollection;
        }

        return filtered;
    } @catch (NSException *containerException) {
        NTYTLog(@"[Filter] container rollback: %@",
                containerException.reason ?: @"<unknown>");
        return originalCollection;
    }
}

@end
