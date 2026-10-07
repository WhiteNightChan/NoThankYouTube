#import "NTYTMetadataExtractor.h"

#import "Core/NTYTContentMetadata.h"
#import "NTYTProtobufReader.h"
#import "NTYTElementQualificationPrivate.h"

static NSErrorDomain const NTYTMetadataExtractorErrorDomain = @"com.whitenightchan.nothankyoutube.extraction";

static NSError *NTYTExtractionError(NSInteger code, NSString *message) {
    return [NSError errorWithDomain:NTYTMetadataExtractorErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: message}];
}

static NSArray<NSNumber *> *NTYTFromYouTubeVideoIDProviderAPath(void) {
    return @[@1, @168777401, @5, @400581496, @2, @2, @5, @169495254,
             @98150882, @1, @66439850, @1, @66441155, @3, @73080600];
}

static NSArray<NSNumber *> *NTYTFromYouTubeVideoIDProviderBPath(void) {
    return @[@1, @168777401, @5, @400581496, @2, @2, @5, @169495254,
             @98150882, @1, @66439850, @1, @66441155, @3, @60666189, @2];
}

static NSArray<NSNumber *> *NTYTFromYouTubeTitleProviderAPath(void) {
    return @[@1, @168777401, @5, @400581496, @2, @2, @1, @2];
}

static NSArray<NSNumber *> *NTYTFromYouTubeTitleProviderBPath(void) {
    return @[@1, @168777401, @5, @400581496, @2, @2, @4, @170382656,
             @1, @169495254, @462702848];
}

static NSArray<NSNumber *> *NTYTFromYouTubeChannelPath(void) {
    return @[@1, @168777401, @5, @400581496, @2, @2, @1, @3, @5,
             @169495254, @48687626];
}

static NSArray<NSNumber *> *NTYTVideoIDProviderAPath(void) {
    return @[@1, @168777401, @5, @232954548, @18, @5, @169495254,
             @98150882, @1, @66439850, @1, @66441155, @3, @73080600];
}

static NSArray<NSNumber *> *NTYTVideoIDProviderBPath(void) {
    return @[@1, @168777401, @5, @232954548, @18, @5, @169495254,
             @98150882, @1, @66439850, @1, @66441155, @3, @60666189, @2];
}

static NSArray<NSArray<NSNumber *> *> *NTYTRichMetadataPaths(void) {
    return @[
        @[@1, @168777401, @5, @232954548, @18, @4, @169495254,
          @462702848, @1, @200453700, @1, @48687757],
        @[@1, @168777401, @5, @232954548, @18, @4, @169495254,
          @462702848, @1, @48687757],
    ];
}

static NSArray<NSNumber *> *NTYTShortsRichProvider1Path(void) {
    return @[@1, @168777401, @5, @232954548, @18, @4, @169495254,
             @462702848];
}

static NSArray<NSNumber *> *NTYTShortsRichProvider2Path(void) {
    return @[@1, @168777401, @5, @232954548, @18, @1, @19, @1, @1,
             @4, @424915055, @1, @3, @48687757];
}

static NSArray<NSNumber *> *NTYTChannelProviderAPath(void) {
    return @[@1, @168777401, @5, @232954548, @18, @1, @3, @5,
             @169495254, @48687626];
}

static NSArray<NSNumber *> *NTYTChannelProviderBPath(void) {
    return @[@1, @168777401, @5, @232954548, @18, @1];
}

static NSArray<NSNumber *> *NTYTCollaborationDiscriminatorPath(void) {
    return @[@1, @168777401, @5, @232954548, @18, @1, @24];
}

static NSArray<NSNumber *> *NTYTCollaboratorElementsPath(void) {
    return @[@1, @168777401, @5, @232954548, @18, @1, @24,
             @513888437, @997, @3, @3, @169495254, @443434441,
             @1, @1, @441573002, @4, @153515154, @172660663,
             @1, @168777401, @5, @413471385];
}

static NSArray<NSNumber *> *NTYTCollaboratorNameParentPath(void) {
    return @[@1, @489973921, @1];
}

static NSArray<NSNumber *> *NTYTCollaboratorIDPath(void) {
    return @[@1, @489973921, @997, @3, @3, @169495254, @48687626];
}

static NSArray<NSNumber *> *NTYTCollaboratorHandlePath(void) {
    return @[@1, @489973921, @1, @5, @3, @169495254, @48687626];
}

static NSArray<NSNumber *> *NTYTPlaylistTitlePath(void) {
    return @[@1, @168777401, @5, @232954548, @18, @1, @21, @8178, @1];
}

static NSArray<NSNumber *> *NTYTPlaylistIDPath(void) {
    return @[@1, @168777401, @5, @232954548, @18, @5, @169495254,
             @98150882, @1, @66439850, @1, @77258115, @3, @469942096,
             @2, @339694216, @2, @48687757];
}

static NSArray<NSNumber *> *NTYTPostRoots(void) {
    return @[@33556213, @33557530, @33561873, @33562168];
}

static NSString *NTYTExactlyOneString(NSArray<NSString *> *strings,
                                      BOOL requireNonEmpty) {
    if (strings.count != 1) {
        return nil;
    }
    NSString *value = strings.firstObject;
    if (requireNonEmpty && value.length == 0) {
        return nil;
    }
    return value;
}

static NSString *NTYTDirectString(NSData *message,
                                  uint32_t fieldNumber,
                                  BOOL requireNonEmpty) {
    if (!message) {
        return nil;
    }
    NSArray<NSString *> *strings =
        [NTYTProtobufReader UTF8StringsForDirectField:fieldNumber
                                            inMessage:message
                                                 error:nil];
    return NTYTExactlyOneString(strings, requireNonEmpty);
}

static NSString *NTYTExactlyOneMessageString(NSData *data,
                                             NSArray<NSNumber *> *path,
                                             uint32_t fieldNumber,
                                             BOOL requireNonEmpty) {
    NSArray<NSData *> *messages =
        [NTYTProtobufReader messagesAtPath:path inData:data error:nil];
    if (messages.count != 1) {
        return nil;
    }
    return NTYTDirectString(messages.firstObject, fieldNumber, requireNonEmpty);
}

static NSString *NTYTSemanticHandleFromSourceString(NSString *source) {
    if ([source hasPrefix:@"/@"]) {
        return [source substringFromIndex:1];
    }
    return source;
}

static NTYTMetadataValue *NTYTMetadataValueForString(NSString *value) {
    return value ? [NTYTMetadataValue availableValue:value]
                 : [NTYTMetadataValue unavailableValue];
}

static NTYTChannelIdentityCollection *NTYTSingleChannelCollection(
    NTYTMetadataValue *channelID,
    NTYTMetadataValue *channelName,
    NTYTMetadataValue *handle) {
    NTYTChannelIdentity *identity =
        [[NTYTChannelIdentity alloc] initWithChannelID:channelID
                                          channelName:channelName
                                               handle:handle];
    return [NTYTChannelIdentityCollection availableWithIdentities:@[identity]]
        ?: [NTYTChannelIdentityCollection unavailableCollection];
}

static NSString *NTYTReconcileStrings(NSString *first, NSString *second) {
    if (first && second) {
        return [first isEqualToString:second] ? first : nil;
    }
    return first ?: second;
}

static NSString *NTYTVideoIDFromProviderA(NSData *data) {
    NSArray<NSData *> *messages =
        [NTYTProtobufReader messagesAtPath:NTYTVideoIDProviderAPath()
                                    inData:data
                                     error:nil];
    if (messages.count != 1) {
        return nil;
    }

    NSData *message = messages.firstObject;
    NSString *primary = NTYTDirectString(message, 1, YES);
    if (!primary) {
        return nil;
    }

    NSArray<NSData *> *corroboratingMessages =
        [NTYTProtobufReader messagesAtPath:@[@8, @382320942]
                                    inData:message
                                     error:nil];
    NSString *corroborating = nil;
    if (corroboratingMessages.count == 1) {
        corroborating = NTYTDirectString(corroboratingMessages.firstObject, 1, YES);
    }
    if (corroborating && ![corroborating isEqualToString:primary]) {
        return nil;
    }
    return primary;
}

static NSString *NTYTResolvedVideoID(NSData *data) {
    NSString *providerA = NTYTVideoIDFromProviderA(data);
    NSString *providerB = NTYTExactlyOneMessageString(data,
                                                       NTYTVideoIDProviderBPath(),
                                                       2,
                                                       YES);
    return NTYTReconcileStrings(providerA, providerB);
}

static NSDictionary<NSNumber *, NSString *> *NTYTVideoRichFields(NSData *data,
                                                                  NSString *videoID) {
    if (!videoID) {
        return @{};
    }

    NSMutableArray<NSData *> *matchingCandidates = [NSMutableArray array];
    for (NSArray<NSNumber *> *path in NTYTRichMetadataPaths()) {
        NSArray<NSData *> *candidates =
            [NTYTProtobufReader messagesAtPath:path inData:data error:nil];
        if (!candidates) {
            return @{};
        }
        for (NSData *candidate in candidates) {
            NSArray<NSString *> *candidateIDStrings =
                [NTYTProtobufReader UTF8StringsForDirectField:1
                                                    inMessage:candidate
                                                         error:nil];
            if (!candidateIDStrings) {
                return @{};
            }
            if (candidateIDStrings.count >= 2) {
                return @{};
            }

            NSString *candidateID = NTYTExactlyOneString(candidateIDStrings, YES);
            if ([candidateID isEqualToString:videoID]) {
                [matchingCandidates addObject:candidate];
            }
        }
    }
    if (matchingCandidates.count != 1) {
        return @{};
    }

    NSData *candidate = matchingCandidates.firstObject;
    NSString *title = NTYTDirectString(candidate, 36, NO);
    NSString *channelName = NTYTDirectString(candidate, 37, NO);
    NSMutableDictionary<NSNumber *, NSString *> *fields = [NSMutableDictionary dictionary];
    if (title) {
        fields[@36] = title;
    }
    if (channelName) {
        fields[@37] = channelName;
    }
    return fields;
}

static NSDictionary<NSNumber *, NSString *> *NTYTShortsVideoRichFields(NSData *data) {
    NSString *title1 = NTYTExactlyOneMessageString(data,
                                                   NTYTShortsRichProvider1Path(),
                                                   4,
                                                   NO);
    NSString *title2 = NTYTExactlyOneMessageString(data,
                                                   NTYTShortsRichProvider2Path(),
                                                   36,
                                                   NO);
    NSString *channelName1 = NTYTExactlyOneMessageString(data,
                                                         NTYTShortsRichProvider1Path(),
                                                         5,
                                                         NO);
    NSString *channelName2 = NTYTExactlyOneMessageString(data,
                                                         NTYTShortsRichProvider2Path(),
                                                         37,
                                                         NO);

    NSString *title = NTYTReconcileStrings(title1, title2);
    NSString *channelName = NTYTReconcileStrings(channelName1, channelName2);

    NSMutableDictionary<NSNumber *, NSString *> *fields =
        [NSMutableDictionary dictionary];
    if (title) {
        fields[@36] = title;
    }
    if (channelName) {
        fields[@37] = channelName;
    }
    return fields;
}

static NSDictionary<NSNumber *, NSString *> *NTYTChannelProviderAFields(NSData *data) {
    NSArray<NSData *> *messages =
        [NTYTProtobufReader messagesAtPath:NTYTChannelProviderAPath()
                                    inData:data
                                     error:nil];
    if (messages.count != 1) {
        return @{};
    }

    NSData *message = messages.firstObject;
    NSString *channelID = NTYTDirectString(message, 2, YES);
    NSString *handle = NTYTDirectString(message, 4, YES);
    NSMutableDictionary<NSNumber *, NSString *> *fields = [NSMutableDictionary dictionary];
    if (channelID) {
        fields[@2] = channelID;
    }
    if (handle) {
        fields[@4] = NTYTSemanticHandleFromSourceString(handle);
    }
    return fields;
}

static NSString *NTYTCollaboratorHandle(NSData *element, NSString *channelID) {
    NSArray<NSData *> *messages =
        [NTYTProtobufReader messagesAtPath:NTYTCollaboratorHandlePath()
                                    inData:element
                                     error:nil];
    if (messages.count != 1) {
        return nil;
    }

    NSData *message = messages.firstObject;
    NSString *providerID = NTYTDirectString(message, 2, YES);
    NSString *source = NTYTDirectString(message, 4, YES);
    if (!providerID || (channelID && ![providerID isEqualToString:channelID]) ||
        ![source hasPrefix:@"/@"] || source.length <= 2) {
        return nil;
    }
    return NTYTSemanticHandleFromSourceString(source);
}

static NTYTChannelIdentityCollection *NTYTCollaboratorCollection(NSData *data) {
    NSArray<NSData *> *elements =
        [NTYTProtobufReader messagesAtPath:NTYTCollaboratorElementsPath()
                                    inData:data
                                     error:nil];
    if (!elements || elements.count == 0) {
        return [NTYTChannelIdentityCollection unavailableCollection];
    }

    NSMutableArray<NTYTChannelIdentity *> *identities =
        [NSMutableArray arrayWithCapacity:elements.count];
    for (NSData *element in elements) {
        NSString *channelName = NTYTExactlyOneMessageString(element,
                                                             NTYTCollaboratorNameParentPath(),
                                                             1, NO);
        NSString *channelID = NTYTExactlyOneMessageString(element,
                                                           NTYTCollaboratorIDPath(),
                                                           2, YES);
        NSString *handle = NTYTCollaboratorHandle(element, channelID);
        [identities addObject:[[NTYTChannelIdentity alloc]
            initWithChannelID:NTYTMetadataValueForString(channelID)
                  channelName:NTYTMetadataValueForString(channelName)
                       handle:NTYTMetadataValueForString(handle)]];
    }
    return [NTYTChannelIdentityCollection availableWithIdentities:identities]
        ?: [NTYTChannelIdentityCollection unavailableCollection];
}

static NTYTChannelIdentityCollection *NTYTVideoChannelCollection(
    NSData *data,
    NSDictionary<NSNumber *, NSString *> *rich) {
    // Only a qualified Video reaches this discriminator. A failed traversal
    // cannot safely authorize the ordinary single-creator providers.
    NSArray<NSData *> *branches =
        [NTYTProtobufReader messagesAtPath:NTYTCollaborationDiscriminatorPath()
                                    inData:data
                                     error:nil];
    if (!branches) {
        return [NTYTChannelIdentityCollection unavailableCollection];
    }
    if (branches.count > 0) {
        return NTYTCollaboratorCollection(data);
    }

    NSDictionary<NSNumber *, NSString *> *channelA = NTYTChannelProviderAFields(data);
    NSString *channelB = NTYTExactlyOneMessageString(data,
                                                      NTYTChannelProviderBPath(),
                                                      9, YES);
    NSString *channelID = NTYTReconcileStrings(channelA[@2], channelB);
    return NTYTSingleChannelCollection(NTYTMetadataValueForString(channelID),
                                       NTYTMetadataValueForString(rich[@37]),
                                       NTYTMetadataValueForString(channelA[@4]));
}

static NTYTContentMetadata *NTYTVideoMetadata(NSData *data,
                                              NTYTShortsClassification shortsClassification) {
    NSString *videoID = NTYTResolvedVideoID(data);
    NSDictionary<NSNumber *, NSString *> *rich =
        shortsClassification == NTYTShortsClassificationShorts
            ? NTYTShortsVideoRichFields(data)
            : NTYTVideoRichFields(data, videoID);
    NTYTChannelIdentityCollection *channels = NTYTVideoChannelCollection(data, rich);

    return [[NTYTContentMetadata alloc]
        initWithContentType:NTYTContentTypeVideo
       shortsClassification:shortsClassification
                    videoID:NTYTMetadataValueForString(videoID)
                      title:NTYTMetadataValueForString(rich[@36])
                   postBody:[NTYTMetadataValue unavailableValue]
                 playlistID:[NTYTMetadataValue unavailableValue]
         channelIdentityCollection:channels];
}

static NTYTContentMetadata *NTYTFromYouTubeVideoMetadata(NSData *data,
                                                         NTYTShortsClassification shortsClassification) {
    NSString *videoIDA = NTYTExactlyOneMessageString(data, NTYTFromYouTubeVideoIDProviderAPath(), 1, YES);
    NSString *videoIDB = NTYTExactlyOneMessageString(data, NTYTFromYouTubeVideoIDProviderBPath(), 2, YES);
    NSString *videoID = NTYTReconcileStrings(videoIDA, videoIDB);
    NSString *titleA = NTYTExactlyOneMessageString(data, NTYTFromYouTubeTitleProviderAPath(), 1, NO);
    NSString *titleB = NTYTExactlyOneMessageString(data, NTYTFromYouTubeTitleProviderBPath(), 4, NO);
    NSString *title = NTYTReconcileStrings(titleA, titleB);
    NSString *channelName = NTYTExactlyOneMessageString(data, NTYTFromYouTubeTitleProviderBPath(), 5, NO);
    NSString *channelID = NTYTExactlyOneMessageString(data, NTYTFromYouTubeChannelPath(), 2, YES);
    NSString *sourceHandle = NTYTExactlyOneMessageString(data, NTYTFromYouTubeChannelPath(), 4, YES);
    NTYTChannelIdentityCollection *channels = NTYTSingleChannelCollection(
        NTYTMetadataValueForString(channelID), NTYTMetadataValueForString(channelName),
        NTYTMetadataValueForString(sourceHandle ? NTYTSemanticHandleFromSourceString(sourceHandle) : nil));
    return [[NTYTContentMetadata alloc]
        initWithContentType:NTYTContentTypeVideo shortsClassification:shortsClassification
                    videoID:NTYTMetadataValueForString(videoID)
                      title:NTYTMetadataValueForString(title)
                   postBody:[NTYTMetadataValue unavailableValue]
                 playlistID:[NTYTMetadataValue unavailableValue]
         channelIdentityCollection:channels];
}

static NSArray<NSNumber *> *NTYTPostPath(NSNumber *root,
                                         NSArray<NSNumber *> *suffix) {
    NSMutableArray<NSNumber *> *path =
        [NSMutableArray arrayWithArray:@[@1, @168777401, @5, root]];
    [path addObjectsFromArray:suffix];
    return path;
}

static NSString *NTYTPostField(NSData *data,
                               NSArray<NSNumber *> *suffix,
                               uint32_t fieldNumber,
                               BOOL requireNonEmpty) {
    NSMutableArray<NSData *> *messages = [NSMutableArray array];
    for (NSNumber *root in NTYTPostRoots()) {
        NSArray<NSData *> *candidates =
            [NTYTProtobufReader messagesAtPath:NTYTPostPath(root, suffix)
                                        inData:data
                                         error:nil];
        if (!candidates) {
            return nil;
        }
        [messages addObjectsFromArray:candidates];
    }
    if (messages.count != 1) {
        return nil;
    }
    return NTYTDirectString(messages.firstObject, fieldNumber, requireNonEmpty);
}

static NTYTContentMetadata *NTYTPostMetadata(NSData *data,
                                             NTYTShortsClassification shortsClassification) {
    NSString *channelName = NTYTPostField(data, @[@1, @1, @3, @1, @1], 3, NO);
    NSArray<NSNumber *> *channelSuffix =
        @[@1, @1, @3, @1, @1, @5, @169495254, @48687626];
    NSString *channelID = NTYTPostField(data, channelSuffix, 2, YES);
    NSString *sourceHandle = NTYTPostField(data, channelSuffix, 4, YES);
    NSString *postBody = NTYTPostField(data, @[@1, @1, @4, @1], 1, NO);
    NTYTChannelIdentityCollection *channels = NTYTSingleChannelCollection(
        NTYTMetadataValueForString(channelID),
        NTYTMetadataValueForString(channelName),
        NTYTMetadataValueForString(
            sourceHandle ? NTYTSemanticHandleFromSourceString(sourceHandle) : nil));

    return [[NTYTContentMetadata alloc]
        initWithContentType:NTYTContentTypePost
       shortsClassification:shortsClassification
                    videoID:[NTYTMetadataValue unavailableValue]
                      title:[NTYTMetadataValue unavailableValue]
                   postBody:NTYTMetadataValueForString(postBody)
                 playlistID:[NTYTMetadataValue unavailableValue]
         channelIdentityCollection:channels];
}

static NSString *NTYTPlaylistID(NSData *data) {
    NSArray<NSData *> *messages =
        [NTYTProtobufReader messagesAtPath:NTYTPlaylistIDPath()
                                    inData:data
                                     error:nil];
    NSMutableSet<NSString *> *uniqueIDs = [NSMutableSet set];
    for (NSData *message in messages ?: @[]) {
        NSArray<NSString *> *values =
            [NTYTProtobufReader UTF8StringsForDirectField:2
                                                inMessage:message
                                                     error:nil];
        if (!values) {
            return nil;
        }
        for (NSString *value in values) {
            if (value.length > 0) {
                [uniqueIDs addObject:value];
            }
        }
    }
    return uniqueIDs.count == 1 ? uniqueIDs.anyObject : nil;
}

static NTYTContentMetadata *NTYTPlaylistMetadata(NSData *data,
                                                  NTYTContentType contentType,
                                                  NTYTShortsClassification shortsClassification) {
    NSString *title = NTYTExactlyOneMessageString(data,
                                                   NTYTPlaylistTitlePath(),
                                                   1,
                                                   NO);
    NSString *playlistID = NTYTPlaylistID(data);
    NSDictionary<NSNumber *, NSString *> *channelFields = @{};
    if (contentType == NTYTContentTypePlaylistNormal) {
        channelFields = NTYTChannelProviderAFields(data);
    }

    NTYTChannelIdentityCollection *channels =
        contentType == NTYTContentTypePlaylistMix
            ? [NTYTChannelIdentityCollection unavailableCollection]
            : NTYTSingleChannelCollection(
                NTYTMetadataValueForString(channelFields[@2]),
                [NTYTMetadataValue unavailableValue],
                NTYTMetadataValueForString(channelFields[@4]));

    return [[NTYTContentMetadata alloc]
        initWithContentType:contentType
       shortsClassification:shortsClassification
                    videoID:[NTYTMetadataValue unavailableValue]
                      title:NTYTMetadataValueForString(title)
                   postBody:[NTYTMetadataValue unavailableValue]
                 playlistID:NTYTMetadataValueForString(playlistID)
         channelIdentityCollection:channels];
}

@interface NTYTMetadataExtractionResult ()

@property(nonatomic, readwrite, getter=isSuccess) BOOL success;
@property(nonatomic, strong, readwrite, nullable) NTYTContentMetadata *metadata;
@property(nonatomic, strong, readwrite, nullable) NSError *error;

@end


@implementation NTYTMetadataExtractionResult

+ (instancetype)successWithMetadata:(NTYTContentMetadata *)metadata {
    NTYTMetadataExtractionResult *result = [self new];
    result.success = YES;
    result.metadata = metadata;
    return result;
}

+ (instancetype)failureWithError:(NSError *)error {
    NTYTMetadataExtractionResult *result = [self new];
    result.success = NO;
    result.error = error;
    return result;
}

@end


@implementation NTYTMetadataExtractor

+ (NTYTMetadataExtractionResult *)extractFromQualifiedElement:(NTYTElementQualification *)qualification {
    NTYTContentType contentType = qualification.semanticResult.projectedContentType;
    if (!qualification || contentType == NTYTContentTypeUnresolved) {
        return [NTYTMetadataExtractionResult failureWithError:
            NTYTExtractionError(1, @"A qualified element renderer is required.")];
    }

    @try {
        // The captured root belongs to the same qualification used by Option evaluation.
        id value = qualification.validatedElementData;
        if (![value isKindOfClass:[NSData class]]) {
            return [NTYTMetadataExtractionResult failureWithError:
                NTYTExtractionError(2, @"The elementData value is not safe NSData input.")];
        }
        NSData *data = (NSData *)value;
        NSError *rootError = nil;
        if (![NTYTProtobufReader validateMessageData:data error:&rootError]) {
            return [NTYTMetadataExtractionResult failureWithError:
                rootError ?: NTYTExtractionError(3, @"The elementData root message is malformed.")];
        }

        NTYTContentMetadata *metadata = nil;
        switch (contentType) {
            case NTYTContentTypeVideo:
                switch (qualification.videoCellVariant) {
                    case NTYTVideoCellVariantFromYouTube:
                        metadata = NTYTFromYouTubeVideoMetadata(data, qualification.semanticResult.shortsClassification);
                        break;
                    case NTYTVideoCellVariantStandard:
                        metadata = NTYTVideoMetadata(data, qualification.semanticResult.shortsClassification);
                        break;
                    default:
                        break;
                }
                break;
            case NTYTContentTypePost:
                metadata = NTYTPostMetadata(data, qualification.semanticResult.shortsClassification);
                break;
            case NTYTContentTypePlaylistNormal:
            case NTYTContentTypePlaylistMix:
                metadata = NTYTPlaylistMetadata(data, contentType, qualification.semanticResult.shortsClassification);
                break;
            case NTYTContentTypeUnresolved:
                break;
        }
        if (!metadata) {
            return [NTYTMetadataExtractionResult failureWithError:
                NTYTExtractionError(4, @"The qualified content type is unsupported.")];
        }
        return [NTYTMetadataExtractionResult successWithMetadata:metadata];
    } @catch (NSException *exception) {
        return [NTYTMetadataExtractionResult failureWithError:
            NTYTExtractionError(5, exception.reason ?: @"Metadata extraction failed internally.")];
    }
}

@end
