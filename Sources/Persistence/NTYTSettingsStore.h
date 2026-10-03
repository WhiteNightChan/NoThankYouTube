#import <Foundation/Foundation.h>

#import "Core/NTYTTypes.h"

@class NTYTRawSettings;
@class NTYTStoredSettings;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSErrorDomain const NTYTSettingsStoreErrorDomain;

typedef NS_ENUM(NSInteger, NTYTSettingsStoreErrorCode) {
    NTYTSettingsStoreErrorRead = 1,
    NTYTSettingsStoreErrorInvalidPropertyList = 2,
    NTYTSettingsStoreErrorUnsupportedVersion = 3,
    NTYTSettingsStoreErrorSerialization = 4,
    NTYTSettingsStoreErrorWrite = 5,
};

@interface NTYTSettingsLoadResult : NSObject

@property(nonatomic, readonly) NTYTSettingsLifecycleState lifecycleState;
@property(nonatomic, strong, readonly, nullable) NTYTRawSettings *rawSettings;
@property(nonatomic, strong, readonly, nullable) NSError *error;

- (instancetype)initWithLifecycleState:(NTYTSettingsLifecycleState)lifecycleState
                            rawSettings:(nullable NTYTRawSettings *)rawSettings
                                  error:(nullable NSError *)error NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

@interface NTYTSettingsStore : NSObject

@property(nonatomic, copy, readonly) NSString *filePath;

- (instancetype)initWithFilePath:(NSString *)filePath NS_DESIGNATED_INITIALIZER;
- (instancetype)init;
+ (NSString *)defaultFilePath;
- (NTYTSettingsLoadResult *)load;
- (BOOL)commitSettings:(NTYTStoredSettings *)settings
                  error:(NSError * _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
