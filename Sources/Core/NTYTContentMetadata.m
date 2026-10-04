#import "NTYTContentMetadata.h"

@interface NTYTMetadataValue ()

- (instancetype)initWithState:(NTYTMetadataValueState)state
                         value:(nullable NSString *)value;

@end


@implementation NTYTMetadataValue

- (instancetype)initWithState:(NTYTMetadataValueState)state
                         value:(NSString *)value {
    self = [super init];
    if (self) {
        _state = state;
        _value = [value copy];
    }
    return self;
}

+ (instancetype)availableValue:(NSString *)value {
    NSParameterAssert([value isKindOfClass:[NSString class]]);
    return [[self alloc] initWithState:NTYTMetadataValueStateAvailable value:value];
}

+ (instancetype)absentValue {
    static NTYTMetadataValue *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [[self alloc] initWithState:NTYTMetadataValueStateAbsent value:nil];
    });
    return value;
}

+ (instancetype)unavailableValue {
    static NTYTMetadataValue *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [[self alloc] initWithState:NTYTMetadataValueStateUnavailable value:nil];
    });
    return value;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

@end

@implementation NTYTChannelIdentity

- (instancetype)initWithChannelID:(NTYTMetadataValue *)channelID
                      channelName:(NTYTMetadataValue *)channelName
                           handle:(NTYTMetadataValue *)handle {
    NSParameterAssert(channelID && channelName && handle);
    self = [super init];
    if (self) {
        _channelID = channelID;
        _channelName = channelName;
        _handle = handle;
    }
    return self;
}

@end

@interface NTYTChannelIdentityCollection ()

- (instancetype)initWithState:(NTYTChannelIdentityCollectionState)state
                   identities:(NSArray<NTYTChannelIdentity *> *)identities;

@end

@implementation NTYTChannelIdentityCollection

- (instancetype)initWithState:(NTYTChannelIdentityCollectionState)state
                   identities:(NSArray<NTYTChannelIdentity *> *)identities {
    NSParameterAssert((state == NTYTChannelIdentityCollectionStateAvailable && identities.count > 0) ||
                      (state == NTYTChannelIdentityCollectionStateUnavailable && identities.count == 0));
    self = [super init];
    if (self) {
        _state = state;
        _identities = [identities copy];
    }
    return self;
}

+ (nullable instancetype)availableWithIdentities:(NSArray<NTYTChannelIdentity *> *)identities {
    if (![identities isKindOfClass:[NSArray class]] || identities.count == 0) {
        return nil;
    }
    for (id identity in identities) {
        if (![identity isKindOfClass:[NTYTChannelIdentity class]]) {
            return nil;
        }
    }
    return [[self alloc] initWithState:NTYTChannelIdentityCollectionStateAvailable
                           identities:identities];
}

+ (instancetype)unavailableCollection {
    static NTYTChannelIdentityCollection *collection;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        collection = [[self alloc] initWithState:NTYTChannelIdentityCollectionStateUnavailable
                                      identities:@[]];
    });
    return collection;
}

@end


@implementation NTYTContentMetadata

- (instancetype)initWithContentType:(NTYTContentType)contentType
               shortsClassification:(NTYTShortsClassification)shortsClassification
                             videoID:(NTYTMetadataValue *)videoID
                               title:(NTYTMetadataValue *)title
                            postBody:(NTYTMetadataValue *)postBody
                          playlistID:(NTYTMetadataValue *)playlistID
         channelIdentityCollection:(NTYTChannelIdentityCollection *)channelIdentityCollection {
    self = [super init];
    if (self) {
        NSParameterAssert(contentType != NTYTContentTypeUnresolved);
        NSParameterAssert(shortsClassification == NTYTShortsClassificationShorts ||
                          shortsClassification == NTYTShortsClassificationNonShorts ||
                          shortsClassification == NTYTShortsClassificationUnavailable);
        NSParameterAssert(videoID && title && postBody && playlistID &&
                          channelIdentityCollection);
        _contentType = contentType;
        _shortsClassification = shortsClassification;
        _videoID = videoID;
        _title = title;
        _postBody = postBody;
        _playlistID = playlistID;
        _channelIdentityCollection = channelIdentityCollection;
    }
    return self;
}

@end
