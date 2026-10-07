#import <Foundation/Foundation.h>

#import "Core/NTYTTypes.h"

@class NTYTContentMetadata;
@class NTYTRuntimeSettingsSnapshot;
@class NTYTSemanticQualificationResult;

NS_ASSUME_NONNULL_BEGIN

@interface NTYTEvaluator : NSObject

+ (NTYTOptionPhaseOutcome)optionOutcomeForQualification:(NTYTSemanticQualificationResult *)qualification
                                               snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot;

+ (NTYTDecision)decisionForMetadata:(NTYTContentMetadata *)metadata
                            snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot;

@end

NS_ASSUME_NONNULL_END
