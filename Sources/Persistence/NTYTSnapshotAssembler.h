#import <Foundation/Foundation.h>

@class NTYTRawSettings;
@class NTYTStoredSettings;
@class NTYTRuntimeSettingsSnapshot;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSErrorDomain const NTYTSnapshotAssemblerErrorDomain;

@interface NTYTSnapshotAssemblyResult : NSObject

@property(nonatomic, strong, readonly) NTYTStoredSettings *acceptedSettings;
@property(nonatomic, strong, readonly) NTYTRuntimeSettingsSnapshot *snapshot;
@property(nonatomic, readonly) BOOL hadDegradation;

- (instancetype)initWithAcceptedSettings:(NTYTStoredSettings *)acceptedSettings
                                  snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot
                            hadDegradation:(BOOL)hadDegradation NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

@interface NTYTSnapshotAssembler : NSObject

+ (nullable NTYTSnapshotAssemblyResult *)assembleRawSettings:(NTYTRawSettings *)rawSettings
                                                        error:(NSError * _Nullable * _Nullable)error;
+ (nullable NTYTRuntimeSettingsSnapshot *)buildStrictSnapshotForSettings:(NTYTStoredSettings *)settings
                                                                    error:(NSError * _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
