#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NTYTSectionCollectionAdapter : NSObject

+ (NSArray *)filteredSectionCollectionFromOriginal:(NSArray *)originalCollection;

+ (NSArray *)filteredStandaloneHorizontalContinuationContents:(NSArray *)contents;

@end

NS_ASSUME_NONNULL_END
