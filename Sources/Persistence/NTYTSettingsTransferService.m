#import "NTYTSettingsTransferService.h"

#import "Debug/LogHelper.h"
#import "NTYTSettingsStore.h"
#import "NTYTSettingsTransferModels.h"
#import "NTYTSnapshotAssembler.h"
#import "NTYTStoredSettings.h"

NSErrorDomain const NTYTSettingsTransferErrorDomain = @"com.whitenightchan.nothankyoutube.transfer";

static NSError *NTYTTransferError(NTYTSettingsTransferErrorCode code, NSError *underlying) {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (underlying) {
        userInfo[NSUnderlyingErrorKey] = underlying;
    }
    return [NSError errorWithDomain:NTYTSettingsTransferErrorDomain code:code userInfo:userInfo];
}

@implementation NTYTSettingsTransferService

- (NTYTPreparedImport *)prepareImportAtURL:(NSURL *)sourceURL error:(NSError **)error {
    if (!sourceURL.isFileURL) {
        if (error) *error = NTYTTransferError(NTYTSettingsTransferErrorRead, nil);
        return nil;
    }

    BOOL accessed = [sourceURL startAccessingSecurityScopedResource];
    @try {
        // Coordination gives file providers one stable read opportunity. The URL is not
        // retained or read again after the resulting settings and snapshot are prepared.
        __block NTYTPreparedImport *prepared = nil;
        __block NSError *preparationError = nil;
        NSError *coordinationError = nil;
        NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
        [coordinator coordinateReadingItemAtURL:sourceURL
                                        options:0
                                          error:&coordinationError
                                     byAccessor:^(NSURL *readURL) {
            NTYTSettingsStore *sourceStore = [[NTYTSettingsStore alloc]
                initWithFilePath:readURL.path];
            NTYTSettingsLoadResult *loaded = [sourceStore load];
            if (loaded.lifecycleState == NTYTSettingsLifecycleStateAbsent) {
                preparationError = NTYTTransferError(NTYTSettingsTransferErrorRead, nil);
                return;
            }
            if (loaded.lifecycleState == NTYTSettingsLifecycleStateSupportedDegraded) {
                preparationError = NTYTTransferError(NTYTSettingsTransferErrorInvalidFile, nil);
                return;
            }
            if (loaded.lifecycleState == NTYTSettingsLifecycleStateUnusable) {
                NTYTSettingsTransferErrorCode category = NTYTSettingsTransferErrorInvalidFile;
                if ([loaded.error.domain isEqualToString:NTYTSettingsStoreErrorDomain]) {
                    if (loaded.error.code == NTYTSettingsStoreErrorRead) {
                        category = NTYTSettingsTransferErrorRead;
                    } else if (loaded.error.code == NTYTSettingsStoreErrorUnsupportedVersion) {
                        category = NTYTSettingsTransferErrorUnsupportedVersion;
                    }
                }
                preparationError = NTYTTransferError(category, loaded.error);
                return;
            }

            NSError *assemblyError = nil;
            NTYTSnapshotAssemblyResult *assembly =
                [NTYTSnapshotAssembler assembleRawSettings:loaded.rawSettings
                                                     error:&assemblyError];
            if (!assembly || assembly.hadDegradation) {
                preparationError = NTYTTransferError(NTYTSettingsTransferErrorValidation,
                                                     assemblyError);
                return;
            }
            prepared = [[NTYTPreparedImport alloc]
                initWithSettings:assembly.acceptedSettings snapshot:assembly.snapshot];
        }];

        if (!prepared && error) {
            *error = preparationError ?: NTYTTransferError(NTYTSettingsTransferErrorRead,
                                                            coordinationError);
        }
        return prepared;
    } @finally {
        if (accessed) {
            [sourceURL stopAccessingSecurityScopedResource];
        }
    }
}

- (NSString *)exportDirectory {
    return [[NSTemporaryDirectory() stringByAppendingPathComponent:@"NoThankYouTube"]
        stringByAppendingPathComponent:@"Exports"];
}

- (void)removeStaleExportsInDirectory:(NSString *)directory {
    NSFileManager *manager = NSFileManager.defaultManager;
    NSError *listError = nil;
    NSArray<NSString *> *names = [manager contentsOfDirectoryAtPath:directory error:&listError];
    if (!names) {
        if (listError.code != NSFileReadNoSuchFileError) {
            NTYTLog(@"[SettingsTransfer] stale export listing failed: %@", listError);
        }
        return;
    }
    for (NSString *name in names) {
        if (![name hasPrefix:@"NoThankYouTube_Settings_"] ||
            ![name hasSuffix:@".plist"]) {
            continue;
        }
        NSString *path = [directory stringByAppendingPathComponent:name];
        BOOL isDirectory = NO;
        if (![manager fileExistsAtPath:path isDirectory:&isDirectory] || isDirectory) {
            continue;
        }
        NSError *removeError = nil;
        if (![manager removeItemAtPath:path error:&removeError]) {
            NTYTLog(@"[SettingsTransfer] stale export cleanup failed: %@", removeError);
        }
    }
}

- (NSURL *)writeExportCapture:(NTYTExportCapture *)capture error:(NSError **)error {
    if (!capture.settings) {
        if (error) *error = NTYTTransferError(NTYTSettingsTransferErrorExportCreation, nil);
        return nil;
    }
    NSString *directory = [self exportDirectory];
    [self removeStaleExportsInDirectory:directory];

    NSError *directoryError = nil;
    if (![NSFileManager.defaultManager createDirectoryAtPath:directory
                                 withIntermediateDirectories:YES
                                                  attributes:nil
                                                       error:&directoryError]) {
        if (error) *error = NTYTTransferError(NTYTSettingsTransferErrorExportCreation,
                                              directoryError);
        return nil;
    }

    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    formatter.dateFormat = @"yyyy-MM-dd_HH-mm-ss";
    NSString *filename = [NSString stringWithFormat:@"NoThankYouTube_Settings_%@.plist",
        [formatter stringFromDate:NSDate.date]];
    NSURL *fileURL = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:filename]];

    NTYTSettingsStore *exportStore = [[NTYTSettingsStore alloc] initWithFilePath:fileURL.path];
    NSError *writeError = nil;
    if (![exportStore commitSettings:capture.settings error:&writeError]) {
        [self removeExportFileAtURL:fileURL];
        if (error) *error = NTYTTransferError(NTYTSettingsTransferErrorExportCreation, writeError);
        return nil;
    }
    return fileURL;
}

- (void)removeExportFileAtURL:(NSURL *)exportURL {
    if (!exportURL.isFileURL ||
        ![[exportURL.path stringByDeletingLastPathComponent].stringByStandardizingPath
            isEqualToString:[self exportDirectory].stringByStandardizingPath] ||
        ![exportURL.lastPathComponent hasPrefix:@"NoThankYouTube_Settings_"] ||
        ![exportURL.lastPathComponent hasSuffix:@".plist"]) {
        return;
    }
    NSError *removeError = nil;
    if (![NSFileManager.defaultManager removeItemAtURL:exportURL error:&removeError] &&
        removeError.code != NSFileNoSuchFileError) {
        NTYTLog(@"[SettingsTransfer] export cleanup failed: %@", removeError);
    }
}

@end
