#import "NTYTTransientMessagePresenter.h"

@implementation NTYTTransientMessagePresenter

+ (void)showMessage:(NSString *)message inViewController:(UIViewController *)controller {
    if (message.length == 0 || !controller.view.window) {
        return;
    }
    UILabel *label = [UILabel new];
    label.text = message;
    label.textColor = UIColor.whiteColor;
    label.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.78];
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;
    label.layer.cornerRadius = 8.0;
    label.layer.masksToBounds = YES;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [controller.view addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
        [label.centerXAnchor constraintEqualToAnchor:controller.view.centerXAnchor],
        [label.bottomAnchor constraintEqualToAnchor:controller.view.safeAreaLayoutGuide.bottomAnchor
                                               constant:-20.0],
        [label.widthAnchor constraintLessThanOrEqualToAnchor:controller.view.widthAnchor
                                                 multiplier:0.82],
    ]];
    [UIView animateWithDuration:0.2
                          delay:1.2
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{ label.alpha = 0.0; }
                     completion:^(__unused BOOL finished) { [label removeFromSuperview]; }];
}

@end
