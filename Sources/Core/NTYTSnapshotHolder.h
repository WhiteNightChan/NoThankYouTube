#import <Foundation/Foundation.h>

@class NTYTRuntimeSettingsSnapshot;

NS_ASSUME_NONNULL_BEGIN

@interface NTYTSnapshotHolder : NSObject

+ (instancetype)sharedHolder;
- (NTYTRuntimeSettingsSnapshot *)currentSnapshot;
- (void)publishSnapshot:(NTYTRuntimeSettingsSnapshot *)snapshot;

@end

NS_ASSUME_NONNULL_END
