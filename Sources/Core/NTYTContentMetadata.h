#import <Foundation/Foundation.h>

#import "NTYTTypes.h"

NS_ASSUME_NONNULL_BEGIN

@interface NTYTContentMetadata : NSObject

@property(nonatomic, readonly) NTYTContentType contentType;
@property(nonatomic, copy, readonly, nullable) NSString *videoID;
@property(nonatomic, copy, readonly, nullable) NSString *title;
@property(nonatomic, copy, readonly, nullable) NSString *channelID;
@property(nonatomic, copy, readonly, nullable) NSString *channelName;
@property(nonatomic, copy, readonly, nullable) NSString *handle;

- (instancetype)initWithContentType:(NTYTContentType)contentType
                             videoID:(nullable NSString *)videoID
                               title:(nullable NSString *)title
                           channelID:(nullable NSString *)channelID
                         channelName:(nullable NSString *)channelName
                              handle:(nullable NSString *)handle NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
