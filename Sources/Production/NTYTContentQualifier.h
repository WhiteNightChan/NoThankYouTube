#import <Foundation/Foundation.h>

#import "Core/NTYTSemanticQualification.h"

@class YTIElementRenderer;

NS_ASSUME_NONNULL_BEGIN

// Production passes this opaque CQMDE context to extraction after Option evaluation.
@interface NTYTElementQualification : NSObject
@property(nonatomic, strong, readonly) NTYTSemanticQualificationResult *semanticResult;
- (instancetype)init NS_UNAVAILABLE;
@end

@interface NTYTContentQualifier : NSObject

+ (NTYTElementQualification *)qualificationForElementRenderer:(YTIElementRenderer *)elementRenderer;
// The continuation route supports only the standalone Horizontal Shelf target.
+ (NTYTElementQualification *)qualificationForStandaloneHorizontalElementRenderer:(YTIElementRenderer *)elementRenderer;
// Receives an already resolved HorizontalList unit; never filters individual cells.
+ (NTYTSemanticQualificationResult *)qualificationForHorizontalListItems:(NSArray *)items;

@end

NS_ASSUME_NONNULL_END
