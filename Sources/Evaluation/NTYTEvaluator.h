#import <Foundation/Foundation.h>

#import "Core/NTYTTypes.h"

@class NTYTContentMetadata;
@class NTYTRuntimeSettingsSnapshot;

NS_ASSUME_NONNULL_BEGIN

@interface NTYTEvaluator : NSObject

+ (NTYTDecision)decisionForMetadata:(NTYTContentMetadata *)metadata
                            snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot;

@end

NS_ASSUME_NONNULL_END
