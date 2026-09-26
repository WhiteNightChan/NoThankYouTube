#import "NTYTSettingsTransferFlowController.h"

#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <objc/runtime.h>

#import "NTYTTransientMessagePresenter.h"
#import "Localization/NTYTUIStrings.h"
#import "Localization/NTYTErrorStrings.h"
#import "Persistence/NTYTSettingsCoordinator.h"
#import "Persistence/NTYTSettingsTransferModels.h"
#import "Persistence/NTYTSettingsTransferService.h"

static void *NTYTTransferSessionKey = &NTYTTransferSessionKey;
// Accessed only on the main thread. A second Export must not clean the temporary file used by an active Export picker.
static BOOL NTYTExportSessionActive = NO;

@interface NTYTSettingsTransferFlowController () <UIDocumentPickerDelegate>
@property(nonatomic, weak) UIViewController *presenter;
@property(nonatomic, strong) NTYTSettingsTransferService *service;
@property(nonatomic, strong) NTYTPreparedImport *pendingImport;
@property(nonatomic, strong) NSURL *exportURL;
@property(nonatomic) BOOL exportSession;
@end

@implementation NTYTSettingsTransferFlowController

+ (instancetype)beginInViewController:(UIViewController *)presenter {
    if (!presenter || !presenter.view.window ||
        objc_getAssociatedObject(presenter, NTYTTransferSessionKey)) {
        return nil;
    }
    NTYTSettingsTransferFlowController *flow = [self new];
    flow.presenter = presenter;
    flow.service = [NTYTSettingsTransferService new];
    objc_setAssociatedObject(presenter, NTYTTransferSessionKey, flow,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return flow;
}

+ (void)startImportFromViewController:(UIViewController *)presenter {
    NTYTSettingsTransferFlowController *flow = [self beginInViewController:presenter];
    if (flow) [flow presentImportDocumentPicker];
}

+ (void)startExportFromViewController:(UIViewController *)presenter {
    if (NTYTExportSessionActive) return;
    NTYTSettingsTransferFlowController *flow = [self beginInViewController:presenter];
    if (!flow) return;
    NTYTExportSessionActive = YES;
    flow.exportSession = YES;
    [flow beginExport];
}

- (void)finish {
    if (self.exportURL) {
        [self.service removeExportFileAtURL:self.exportURL];
        self.exportURL = nil;
    }
    self.pendingImport = nil;
    if (self.exportSession) {
        NTYTExportSessionActive = NO;
        self.exportSession = NO;
    }
    UIViewController *presenter = self.presenter;
    if (presenter && objc_getAssociatedObject(presenter, NTYTTransferSessionKey) == self) {
        objc_setAssociatedObject(presenter, NTYTTransferSessionKey, nil,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (void)notify:(NSString *)message {
    if (self.presenter) {
        [NTYTTransientMessagePresenter showMessage:message inViewController:self.presenter];
    }
}

- (void)presentImportDocumentPicker {
    UIViewController *presenter = self.presenter;
    if (!presenter.view.window || presenter.presentedViewController) {
        [self notify:NTYTImportPickerUnavailableText()];
        [self finish];
        return;
    }
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc]
        initForOpeningContentTypes:@[UTTypePropertyList]];
    picker.allowsMultipleSelection = NO;
    picker.delegate = self;
    @try {
        [presenter presentViewController:picker animated:YES completion:^{
            if (!picker.view.window && self.presenter) {
                [self notify:NTYTImportPickerUnavailableText()];
                [self finish];
            }
        }];
    } @catch (__unused NSException *exception) {
        [self notify:NTYTImportPickerUnavailableText()];
        [self finish];
    }
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    [self finish];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller
 didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    if (self.exportSession) {
        [self notify:NTYTExportSuccessText()];
        [self finish];
        return;
    }
    if (urls.count != 1) {
        [self notify:NTYTImportInvalidSelectionText()];
        [self finish];
        return;
    }
    NSURL *sourceURL = urls.firstObject;
    // The picker interaction ends before presenting a possible replacement Alert.
    [controller dismissViewControllerAnimated:YES completion:^{
        [self prepareImportFromURL:sourceURL];
    }];
}

- (void)prepareImportFromURL:(NSURL *)sourceURL {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSError *error = nil;
        NTYTPreparedImport *prepared = [self.service prepareImportAtURL:sourceURL error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!prepared) {
                [self notify:NTYTSettingsTransferErrorText(error)];
                [self finish];
                return;
            }
            self.pendingImport = prepared;
            [self attemptImportWithToken:nil];
        });
    });
}

- (void)attemptImportWithToken:(NSUUID *)token {
    NTYTImportCommitResult *result = [[NTYTSettingsCoordinator sharedCoordinator]
        commitPreparedImport:self.pendingImport confirmationToken:token];
    switch (result.status) {
        case NTYTImportCommitStatusConfirmationRequired:
            [self confirmReplacementWithToken:result.confirmationToken];
            return;
        case NTYTImportCommitStatusSuccess:
            [self notify:NTYTImportSuccessText()];
            break;
        case NTYTImportCommitStatusNoChange:
            [self notify:NTYTImportNoChangesText()];
            break;
        case NTYTImportCommitStatusFailure:
            [self notify:NTYTImportCommitErrorText(result)];
            break;
    }
    [self finish];
}

- (void)confirmReplacementWithToken:(NSUUID *)token {
    UIViewController *presenter = self.presenter;
    if (!presenter.view.window || presenter.presentedViewController) {
        [self notify:NTYTImportConfirmationUnavailableText()];
        [self finish];
        return;
    }
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:NTYTImportReplaceTitle()
                   message:NTYTImportReplaceMessage()
            preferredStyle:UIAlertControllerStyleAlert];
    __weak UIAlertController *weakAlert = alert;
    [alert addAction:[UIAlertAction actionWithTitle:NTYTCancelTitle()
                                             style:UIAlertActionStyleCancel
                                           handler:^(__unused UIAlertAction *action) {
        [self finish];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:NTYTImportReplaceActionTitle()
                                             style:UIAlertActionStyleDestructive
                                           handler:^(__unused UIAlertAction *action) {
        // Wait until this Alert is gone before a destination race can show another.
        [weakAlert dismissViewControllerAnimated:YES completion:^{
            [self attemptImportWithToken:token];
        }];
    }]];
    @try {
        [presenter presentViewController:alert animated:YES completion:^{
            if (!alert.view.window && self.pendingImport) {
                [self notify:NTYTImportConfirmationUnavailableText()];
                [self finish];
            }
        }];
    } @catch (__unused NSException *exception) {
        [self notify:NTYTImportConfirmationUnavailableText()];
        [self finish];
    }
}

- (void)beginExport {
    NTYTExportCapture *capture = [[NTYTSettingsCoordinator sharedCoordinator]
        captureSettingsForExport];
    if (!capture) {
        [self notify:NTYTExportUnavailableText()];
        [self finish];
        return;
    }

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSError *error = nil;
        NSURL *fileURL = [self.service writeExportCapture:capture error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!fileURL) {
                [self notify:NTYTSettingsTransferErrorText(error)];
                [self finish];
                return;
            }
            self.exportURL = fileURL;
            if (capture.isSalvage) {
                // Show the notice while the root is visible, before the picker covers it.
                [self notify:NTYTExportSalvageNoticeText()];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.6 * NSEC_PER_SEC)),
                               dispatch_get_main_queue(), ^{ [self presentExportDocumentPicker]; });
            } else {
                [self presentExportDocumentPicker];
            }
        });
    });
}

- (void)presentExportDocumentPicker {
    UIViewController *presenter = self.presenter;
    if (!presenter.view.window || presenter.presentedViewController || !self.exportURL) {
        [self notify:NTYTExportPickerUnavailableText()];
        [self finish];
        return;
    }
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc]
        initForExportingURLs:@[self.exportURL] asCopy:YES];
    picker.delegate = self;
    @try {
        [presenter presentViewController:picker animated:YES completion:^{
            if (!picker.view.window && self.presenter) {
                [self notify:NTYTExportPickerUnavailableText()];
                [self finish];
            }
        }];
    } @catch (__unused NSException *exception) {
        [self notify:NTYTExportPickerUnavailableText()];
        [self finish];
    }
}

@end
