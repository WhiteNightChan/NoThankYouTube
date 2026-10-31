#import "NTYTRuleListViewController.h"

@class NTYTListEditingAdapter;
@class NTYTRuleListState;
@class NTYTSettingsCell;

NS_ASSUME_NONNULL_BEGIN

@interface NTYTRuleListViewController () <UITextViewDelegate, UIGestureRecognizerDelegate, UISearchBarDelegate>

@property(nonatomic, strong, readonly) NTYTListEditingAdapter *editingAdapter;
@property(nonatomic, strong, readonly) NTYTRuleListState *state;

@property(nonatomic, strong) UISearchBar *searchBar;
// Editing-local input storage.
@property(nonatomic, copy, nullable) NSString *currentInputPlaceholder;
// Presentation-local layout storage.
@property(nonatomic) BOOL hasAppliedInitialSearchBarOffset;
@property(nonatomic) CGFloat initialTableViewOffsetY;
@property(nonatomic, strong, nullable) NTYTSettingsCell *sizingCell;

- (void)reloadAuthoritativeStateAndRender;
- (void)renderCurrentState;
- (void)applySelectionProjectionToTableView;

- (BOOL)currentListMutationsAllowed;
- (NTYTSettingsLifecycleState)currentSettingsLifecycleState;
- (void)synchronizeEditingStateWithMutationAvailability;

// Cross-responsibility coordination stays in the Controller.
- (void)refreshSelectionPresentation;
- (void)refreshEditingModePresentationAnimated:(BOOL)animated;
- (void)presentEditingFailureMessage:(NSString *)message;

- (void)goBack;
- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture;

@end

// Selector declarations for passive button wiring, without category imports.
// Implementations and interaction policy belong to the Editing category.
@interface NTYTRuleListViewController (InternalActionTargets)
- (void)addButtonTapped;
- (void)editButtonTapped;
- (void)selectAllButtonTapped;
- (void)deleteSelectedItemsTapped;
@end

NS_ASSUME_NONNULL_END
