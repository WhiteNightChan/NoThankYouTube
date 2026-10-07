#import <Foundation/Foundation.h>

@class NTYTRuntimeSettingsSnapshot;
@class YTIElementRenderer;

NS_ASSUME_NONNULL_BEGIN

@interface NTYTProductionFilter : NSObject

+ (BOOL)shouldRemoveContentEntry:(id)entry
                        snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot
                      childIndex:(NSUInteger)childIndex;

+ (BOOL)shouldRemoveStandaloneHorizontalElement:(id)element
                                        snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot;
+ (BOOL)shouldRemoveHorizontalListItems:(NSArray *)items
                               snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot;

@end

NS_ASSUME_NONNULL_END
