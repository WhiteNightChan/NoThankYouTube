#import <Foundation/Foundation.h>

#import "NTYTTypes.h"

NS_ASSUME_NONNULL_BEGIN

@interface NTYTMetadataValue : NSObject <NSCopying>

@property(nonatomic, readonly) NTYTMetadataValueState state;
@property(nonatomic, copy, readonly, nullable) NSString *value;

+ (instancetype)availableValue:(NSString *)value;
+ (instancetype)absentValue;
+ (instancetype)unavailableValue;
- (instancetype)init NS_UNAVAILABLE;

@end

@interface NTYTContentMetadata : NSObject

@property(nonatomic, readonly) NTYTContentType contentType;
@property(nonatomic, strong, readonly) NTYTMetadataValue *videoID;
@property(nonatomic, strong, readonly) NTYTMetadataValue *title;
@property(nonatomic, strong, readonly) NTYTMetadataValue *postBody;
@property(nonatomic, strong, readonly) NTYTMetadataValue *playlistID;
@property(nonatomic, strong, readonly) NTYTMetadataValue *channelID;
@property(nonatomic, strong, readonly) NTYTMetadataValue *channelName;
@property(nonatomic, strong, readonly) NTYTMetadataValue *handle;

- (instancetype)initWithContentType:(NTYTContentType)contentType
                             videoID:(NTYTMetadataValue *)videoID
                               title:(NTYTMetadataValue *)title
                            postBody:(NTYTMetadataValue *)postBody
                          playlistID:(NTYTMetadataValue *)playlistID
                           channelID:(NTYTMetadataValue *)channelID
                         channelName:(NTYTMetadataValue *)channelName
                              handle:(NTYTMetadataValue *)handle NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
