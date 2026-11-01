#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NTYTSectionCollectionAdapter : NSObject

+ (void)filterSectionCollection:(NSArray *)sectionCollection;

+ (NSArray *)filteredStandaloneHorizontalContinuationContents:(NSArray *)contents;

@end

NS_ASSUME_NONNULL_END
