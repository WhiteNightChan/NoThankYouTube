#import <Foundation/Foundation.h>

#import "Core/NTYTTypes.h"

@class NTYTContentMetadata;
@class YTIElementRenderer;

NS_ASSUME_NONNULL_BEGIN

@interface NTYTMetadataExtractionResult : NSObject

@property(nonatomic, readonly, getter=isSuccess) BOOL success;
@property(nonatomic, strong, readonly, nullable) NTYTContentMetadata *metadata;
@property(nonatomic, strong, readonly, nullable) NSError *error;

+ (instancetype)successWithMetadata:(NTYTContentMetadata *)metadata;
+ (instancetype)failureWithError:(NSError *)error;

@end

@interface NTYTMetadataExtractor : NSObject

+ (NTYTMetadataExtractionResult *)extractFromElementRenderer:(YTIElementRenderer *)elementRenderer
                                        qualifiedContentType:(NTYTContentType)contentType;

@end

NS_ASSUME_NONNULL_END
