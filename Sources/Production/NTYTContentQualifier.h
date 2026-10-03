#import <Foundation/Foundation.h>

#import "Core/NTYTTypes.h"

@class YTIElementRenderer;

NS_ASSUME_NONNULL_BEGIN

@interface NTYTContentQualifier : NSObject

+ (NTYTContentType)qualifiedContentTypeForElementRenderer:(YTIElementRenderer *)elementRenderer;

@end

NS_ASSUME_NONNULL_END
