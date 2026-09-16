#import "NTYTCategoryViewController.h"

#import "Core/NTYTListDefinition.h"
#import "ListView/NTYTRuleListViewController.h"
#import "ListView/NTYTLVTextCell.h"
#import "NTYTUIStrings.h"
#import "Persistence/NTYTSettingsCoordinator.h"

@interface NTYTOptionSwitch : UISwitch
@property(nonatomic) NTYTListID listID;
@property(nonatomic) NTYTListOptionID optionID;
@end

@implementation NTYTOptionSwitch
@end

@interface NTYTCategoryViewController ()
@property(nonatomic) NTYTSettingsCategoryPage categoryPage;
@property(nonatomic, copy) NSArray<NSNumber *> *listIDs;
@end

@implementation NTYTCategoryViewController

- (instancetype)initWithCategoryPage:(NTYTSettingsCategoryPage)categoryPage {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _categoryPage = categoryPage;
        switch (categoryPage) {
            case NTYTSettingsCategoryPageGeneral:
                _listIDs = @[@(NTYTListIDGeneralBlock), @(NTYTListIDGeneralAllow)];
                break;
            case NTYTSettingsCategoryPageVideos:
                _listIDs = @[@(NTYTListIDVideosTitle),
                             @(NTYTListIDVideosChannel),
                             @(NTYTListIDVideosID)];
                break;
            case NTYTSettingsCategoryPageChannels:
                _listIDs = @[@(NTYTListIDChannelsBlock), @(NTYTListIDChannelsAllow)];
                break;
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.tableFooterView = [UIView new];
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    [self.tableView registerClass:NTYTLVTextCell.class
           forCellReuseIdentifier:@"NTYTCategoryCell"];

    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.leftBarButtonItems = @[
        [self backBarButtonItem],
        [self titleBarButtonItem],
    ];

    UIGestureRecognizer *gesture = self.navigationController.interactivePopGestureRecognizer;
    if (gesture) {
        gesture.enabled = YES;
    }

    [self updateLifecyclePresentation];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateLifecyclePresentation];
    [self.tableView reloadData];
}

- (UIBarButtonItem *)backBarButtonItem {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImageSymbolConfiguration *configuration =
        [UIImageSymbolConfiguration configurationWithPointSize:18.5
                                                       weight:UIImageSymbolWeightLight];
    UIImage *image = [[UIImage systemImageNamed:@"chevron.left"
                               withConfiguration:configuration]
        imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [button setImage:image forState:UIControlStateNormal];
    button.tintColor = UIColor.labelColor;
    button.frame = CGRectMake(0, 0, 42, 44);
    [button addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 42, 44)];
    [container addSubview:button];
    return [[UIBarButtonItem alloc] initWithCustomView:container];
}

- (UIBarButtonItem *)titleBarButtonItem {
    UILabel *label = [UILabel new];
    label.text = NTYTCategoryTitle(self.categoryPage);
    label.textColor = UIColor.labelColor;
    label.font = [UIFont fontWithName:@"YouTubeSans-Bold" size:20.0]
        ?: [UIFont boldSystemFontOfSize:20.0];
    [label sizeToFit];
    CGFloat offset = -4.0;
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0,
                                                                 label.bounds.size.width - offset,
                                                                 44.0)];
    container.userInteractionEnabled = NO;
    CGRect frame = label.frame;
    frame.origin.x = offset;
    frame.origin.y = floor((44.0 - frame.size.height) / 2.0);
    label.frame = frame;
    [container addSubview:label];
    return [[UIBarButtonItem alloc] initWithCustomView:container];
}

- (void)goBack {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)updateLifecyclePresentation {
    NTYTSettingsCoordinator *coordinator = NTYTSettingsCoordinator.sharedCoordinator;
    if (coordinator.mutationsAllowed) {
        self.navigationItem.prompt = nil;
    } else {
        self.navigationItem.prompt =
            [NSString stringWithFormat:@"Read-only — %@",
                NTYTSettingsLifecycleDescription(coordinator.lifecycleState)];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.listIDs.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NTYTListDefinition *definition =
        [NTYTListDefinition definitionForListID:(NTYTListID)self.listIDs[section].integerValue];
    return 1 + definition.supportedOptions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NTYTLVTextCell *cell =
        [tableView dequeueReusableCellWithIdentifier:@"NTYTCategoryCell"
                                        forIndexPath:indexPath];
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    NTYTListID listID = (NTYTListID)self.listIDs[indexPath.section].integerValue;
    NTYTListDefinition *definition = [NTYTListDefinition definitionForListID:listID];

    if (indexPath.row == 0) {
        [cell configureWithText:NTYTListTitle(listID)];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return cell;
    }

    NSArray<NSNumber *> *orderedOptions = @[
        @(NTYTListOptionIDCaseSensitive),
        @(NTYTListOptionIDExactMatch),
    ];
    NSMutableArray<NSNumber *> *supported = [NSMutableArray array];
    for (NSNumber *option in orderedOptions) {
        if ([definition.supportedOptions containsObject:option]) {
            [supported addObject:option];
        }
    }
    NTYTListOptionID optionID = (NTYTListOptionID)supported[indexPath.row - 1].integerValue;
    [cell configureWithText:NTYTOptionTitle(optionID)];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    NTYTOptionSwitch *toggle = [NTYTOptionSwitch new];
    toggle.listID = listID;
    toggle.optionID = optionID;
    toggle.on = [[NTYTSettingsCoordinator sharedCoordinator]
        effectiveValueForOption:optionID listID:listID];
    toggle.enabled = NTYTSettingsCoordinator.sharedCoordinator.mutationsAllowed;
    [toggle addTarget:self action:@selector(optionSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = toggle;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row != 0) {
        return;
    }
    NTYTListID listID = (NTYTListID)self.listIDs[indexPath.section].integerValue;
    NTYTRuleListViewController *controller =
        [[NTYTRuleListViewController alloc] initWithListID:listID title:NTYTListTitle(listID)];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)optionSwitchChanged:(NTYTOptionSwitch *)sender {
    NTYTMutationResult *result =
        [[NTYTSettingsCoordinator sharedCoordinator] setEffectiveValue:sender.isOn
                                                             forOption:sender.optionID
                                                                 listID:sender.listID];
    [self.tableView reloadData];
    [self updateLifecyclePresentation];
    if (!result.isSuccess) {
        UIAlertController *alert =
            [UIAlertController alertControllerWithTitle:@"NoThankYouTube"
                                                message:result.message
                                         preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                  style:UIAlertActionStyleDefault
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

@end
