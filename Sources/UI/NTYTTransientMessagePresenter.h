#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NTYTTransientMessagePresenter : NSObject

+ (void)showMessage:(NSString *)message inViewController:(UIViewController *)controller;

@end

NS_ASSUME_NONNULL_END
