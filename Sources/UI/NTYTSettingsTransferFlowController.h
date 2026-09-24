#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Owns one user interaction session; retained by the presenting controller until it ends.
@interface NTYTSettingsTransferFlowController : NSObject

+ (void)startImportFromViewController:(UIViewController *)presenter;
+ (void)startExportFromViewController:(UIViewController *)presenter;

@end

NS_ASSUME_NONNULL_END
