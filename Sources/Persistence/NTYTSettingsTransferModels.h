#import <Foundation/Foundation.h>

#import "Core/NTYTTypes.h"

@class NTYTStoredSettings;
@class NTYTRuntimeSettingsSnapshot;

NS_ASSUME_NONNULL_BEGIN

// A single, fully validated source state. The external URL is not retained.
@interface NTYTPreparedImport : NSObject

@property(nonatomic, strong, readonly) NTYTStoredSettings *settings;
@property(nonatomic, strong, readonly) NTYTRuntimeSettingsSnapshot *snapshot;

- (instancetype)initWithSettings:(NTYTStoredSettings *)settings
                       snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

// One committed state captured under the Coordinator's settings queue.
@interface NTYTExportCapture : NSObject

@property(nonatomic, strong, readonly) NTYTStoredSettings *settings;
@property(nonatomic, readonly) NTYTSettingsLifecycleState sourceLifecycle;
@property(nonatomic, readonly, getter=isSalvage) BOOL salvage;

- (instancetype)initWithSettings:(NTYTStoredSettings *)settings
                  sourceLifecycle:(NTYTSettingsLifecycleState)sourceLifecycle NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
