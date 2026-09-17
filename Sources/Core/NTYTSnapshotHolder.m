#import "NTYTSnapshotHolder.h"

#import "NTYTRuntimeModel.h"

@interface NTYTSnapshotHolder ()

@property(nonatomic, strong) NTYTRuntimeSettingsSnapshot *snapshot;

- (instancetype)initPrivate;

@end

@implementation NTYTSnapshotHolder

+ (instancetype)sharedHolder {
    static NTYTSnapshotHolder *holder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        holder = [[self alloc] initPrivate];
    });
    return holder;
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        _snapshot = [NTYTRuntimeSettingsSnapshot emptySnapshot];
    }
    return self;
}

- (instancetype)init {
    return [NTYTSnapshotHolder sharedHolder];
}

- (NTYTRuntimeSettingsSnapshot *)currentSnapshot {
    @synchronized (self) {
        return self.snapshot;
    }
}

- (void)publishSnapshot:(NTYTRuntimeSettingsSnapshot *)snapshot {
    NSParameterAssert(snapshot != nil);
    @synchronized (self) {
        self.snapshot = snapshot;
    }
}

@end
