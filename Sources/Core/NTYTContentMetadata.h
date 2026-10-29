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

@interface NTYTChannelIdentity : NSObject

@property(nonatomic, strong, readonly) NTYTMetadataValue *channelID;
@property(nonatomic, strong, readonly) NTYTMetadataValue *channelName;
@property(nonatomic, strong, readonly) NTYTMetadataValue *handle;

- (instancetype)initWithChannelID:(NTYTMetadataValue *)channelID
                      channelName:(NTYTMetadataValue *)channelName
                           handle:(NTYTMetadataValue *)handle NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

typedef NS_ENUM(NSInteger, NTYTChannelIdentityCollectionState) {
    NTYTChannelIdentityCollectionStateAvailable = 0,
    NTYTChannelIdentityCollectionStateUnavailable,
};

@interface NTYTChannelIdentityCollection : NSObject

@property(nonatomic, readonly) NTYTChannelIdentityCollectionState state;
@property(nonatomic, copy, readonly) NSArray<NTYTChannelIdentity *> *identities;

+ (nullable instancetype)availableWithIdentities:(NSArray<NTYTChannelIdentity *> *)identities;
+ (instancetype)unavailableCollection;
- (instancetype)init NS_UNAVAILABLE;

@end

@interface NTYTContentMetadata : NSObject

@property(nonatomic, readonly) NTYTContentType contentType;
@property(nonatomic, readonly) NTYTShortsClassification shortsClassification;
@property(nonatomic, readonly) NTYTStationClassification stationClassification;
@property(nonatomic, readonly) NTYTTemporalClassification upcomingClassification;
@property(nonatomic, readonly) NTYTTemporalClassification currentClassification;
@property(nonatomic, strong, readonly) NTYTMetadataValue *videoID;
@property(nonatomic, strong, readonly) NTYTMetadataValue *title;
@property(nonatomic, strong, readonly) NTYTMetadataValue *postBody;
@property(nonatomic, strong, readonly) NTYTMetadataValue *postID;
@property(nonatomic, strong, readonly) NTYTMetadataValue *playlistID;
@property(nonatomic, strong, readonly) NTYTChannelIdentityCollection *channelIdentityCollection;

- (instancetype)initWithContentType:(NTYTContentType)contentType
               shortsClassification:(NTYTShortsClassification)shortsClassification
              stationClassification:(NTYTStationClassification)stationClassification
             upcomingClassification:(NTYTTemporalClassification)upcomingClassification
              currentClassification:(NTYTTemporalClassification)currentClassification
                             videoID:(NTYTMetadataValue *)videoID
                               title:(NTYTMetadataValue *)title
                            postBody:(NTYTMetadataValue *)postBody
                              postID:(NTYTMetadataValue *)postID
                          playlistID:(NTYTMetadataValue *)playlistID
         channelIdentityCollection:(NTYTChannelIdentityCollection *)channelIdentityCollection NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
