#import "Production/NTYTContentQualifier.h"

NS_ASSUME_NONNULL_BEGIN

// CQMDE-only provider selection. Evaluator, Settings and UI consume semanticResult only.
typedef NS_ENUM(NSInteger, NTYTVideoCellVariant) {
    NTYTVideoCellVariantStandard = 0,
    NTYTVideoCellVariantFromYouTube,
};

@interface NTYTElementQualification ()
@property(nonatomic, copy, readonly, nullable) NSData *validatedElementData;
@property(nonatomic, readonly) NTYTVideoCellVariant videoCellVariant;
- (instancetype)initWithSemanticResult:(NTYTSemanticQualificationResult *)semanticResult
                  validatedElementData:(nullable NSData *)validatedElementData
                      videoCellVariant:(NTYTVideoCellVariant)videoCellVariant;
@end

NS_ASSUME_NONNULL_END
