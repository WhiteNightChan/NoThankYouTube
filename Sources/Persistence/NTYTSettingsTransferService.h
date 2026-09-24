#import <Foundation/Foundation.h>

@class NTYTPreparedImport;
@class NTYTExportCapture;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSErrorDomain const NTYTSettingsTransferErrorDomain;

typedef NS_ENUM(NSInteger, NTYTSettingsTransferErrorCode) {
    NTYTSettingsTransferErrorRead = 1,
    NTYTSettingsTransferErrorInvalidFile,
    NTYTSettingsTransferErrorUnsupportedVersion,
    NTYTSettingsTransferErrorValidation,
    NTYTSettingsTransferErrorExportCreation,
};

// External input and non-canonical temporary output only. Call from a background queue.
@interface NTYTSettingsTransferService : NSObject

- (nullable NTYTPreparedImport *)prepareImportAtURL:(NSURL *)sourceURL
                                               error:(NSError * _Nullable * _Nullable)error;
- (nullable NSURL *)writeExportCapture:(NTYTExportCapture *)capture
                                  error:(NSError * _Nullable * _Nullable)error;
- (void)removeExportFileAtURL:(NSURL *)exportURL;

@end

NS_ASSUME_NONNULL_END
