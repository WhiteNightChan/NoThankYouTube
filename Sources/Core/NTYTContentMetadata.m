#import "NTYTContentMetadata.h"

@implementation NTYTContentMetadata

- (instancetype)initWithContentType:(NTYTContentType)contentType
                             videoID:(NSString *)videoID
                               title:(NSString *)title
                           channelID:(NSString *)channelID
                         channelName:(NSString *)channelName
                              handle:(NSString *)handle {
    self = [super init];
    if (self) {
        _contentType = contentType;
        _videoID = [videoID copy];
        _title = [title copy];
        _channelID = [channelID copy];
        _channelName = [channelName copy];
        _handle = [handle copy];
    }
    return self;
}

@end
