#import <Foundation/Foundation.h>

@class NTYTRuntimeSettingsSnapshot;

NS_ASSUME_NONNULL_BEGIN

@interface NTYTProductionFilter : NSObject

+ (BOOL)shouldRemoveContentEntry:(id)entry
                        snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot
                      childIndex:(NSUInteger)childIndex;

@end

NS_ASSUME_NONNULL_END
