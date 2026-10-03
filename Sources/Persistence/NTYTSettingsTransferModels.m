#import "NTYTSettingsTransferModels.h"

#import "Core/NTYTRuntimeModel.h"
#import "NTYTStoredSettings.h"

@implementation NTYTPreparedImport

- (instancetype)initWithSettings:(NTYTStoredSettings *)settings
                       snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot {
    self = [super init];
    if (self) {
        _settings = settings;
        _snapshot = snapshot;
    }
    return self;
}

@end

@implementation NTYTExportCapture

- (instancetype)initWithSettings:(NTYTStoredSettings *)settings
                  sourceLifecycle:(NTYTSettingsLifecycleState)sourceLifecycle {
    self = [super init];
    if (self) {
        _settings = settings;
        _sourceLifecycle = sourceLifecycle;
        _salvage = sourceLifecycle == NTYTSettingsLifecycleStateSupportedDegraded;
    }
    return self;
}

@end
