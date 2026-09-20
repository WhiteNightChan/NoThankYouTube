#import "NTYTRuleListViewController.h"

@class NTYTListEditingAdapter;
@class NTYTLVTextCell;
@class NTYTRuleListItem;

NS_ASSUME_NONNULL_BEGIN

@interface NTYTRuleListViewController () <UITextViewDelegate, UIGestureRecognizerDelegate, UISearchBarDelegate>

@property(nonatomic, strong) NTYTListEditingAdapter *editingAdapter;
@property(nonatomic, strong) NSMutableArray<NTYTRuleListItem *> *items;
@property(nonatomic, copy) NSString *currentInputPlaceholder;
@property(nonatomic, strong) UISearchBar *searchBar;
@property(nonatomic) BOOL isSearching;
@property(nonatomic, copy) NSString *searchText;
@property(nonatomic, strong) NSMutableArray<NTYTRuleListItem *> *filteredItems;
@property(nonatomic) BOOL hasAppliedInitialSearchBarOffset;
@property(nonatomic) CGFloat initialTableViewOffsetY;
@property(nonatomic, strong) NTYTLVTextCell *sizingCell;

- (void)addButtonTapped;
- (void)goBack;
- (void)editButtonTapped;
- (void)updateSelectionUIForCurrentState;
- (void)loadItemsFromAuthoritativeSource;
- (void)reloadListDataForCurrentState;
- (void)refreshListUIForCurrentState;
- (void)showTransientMessage:(NSString *)message;
- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture;
- (void)presentFailureMessage:(NSString *)message;

@end


NS_ASSUME_NONNULL_END
