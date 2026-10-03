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


@implementation NTYTContentMetadata

- (instancetype)initWithContentType:(NTYTContentType)contentType
                             videoID:(NTYTMetadataValue *)videoID
                               title:(NTYTMetadataValue *)title
                            postBody:(NTYTMetadataValue *)postBody
                          playlistID:(NTYTMetadataValue *)playlistID
                           channelID:(NTYTMetadataValue *)channelID
                         channelName:(NTYTMetadataValue *)channelName
                              handle:(NTYTMetadataValue *)handle {
    self = [super init];
    if (self) {
        NSParameterAssert(contentType != NTYTContentTypeUnresolved);
        NSParameterAssert(videoID && title && postBody && playlistID &&
                          channelID && channelName && handle);
        _contentType = contentType;
        _videoID = videoID;
        _title = title;
        _postBody = postBody;
        _playlistID = playlistID;
        _channelID = channelID;
        _channelName = channelName;
        _handle = handle;
    }
    return self;
}

@end
