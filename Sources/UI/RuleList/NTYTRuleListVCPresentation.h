#import "NTYTRuleListViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface NTYTRuleListViewController (Presentation)

- (void)configureListPresentation;
- (void)refreshPresentationForCurrentState;
- (void)updateEmptyStateForCurrentState;
- (void)updateNavigationItemsForCurrentState;
- (void)updateToolbarForCurrentState;
- (void)updateSearchBarVisibilityForCurrentState;
- (NSString *)currentCountDisplayText;
- (CGFloat)heightForRuleText:(NSString *)text;
- (void)applyInitialSearchBarOffsetIfNeeded;
- (void)updateInteractivePopGestureEnabled;
- (void)presentFailureMessage:(NSString *)message;
- (void)presentCopyFeedbackForText:(NSString *)text;

// The Controller supplies the existing transition animation choice.
- (void)updateToolbarVisibilityAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
