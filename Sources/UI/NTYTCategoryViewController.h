#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, NTYTSettingsCategoryPage) {
    NTYTSettingsCategoryPageGeneral = 0,
    NTYTSettingsCategoryPageVideos = 1,
    NTYTSettingsCategoryPageChannels = 2,
    NTYTSettingsCategoryPagePosts = 3,
    NTYTSettingsCategoryPagePlaylists = 4,
    NTYTSettingsCategoryPageGlobal = 5,
};

@interface NTYTCategoryViewController : UITableViewController

- (instancetype)initWithCategoryPage:(NTYTSettingsCategoryPage)categoryPage NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithStyle:(UITableViewStyle)style NS_UNAVAILABLE;
- (instancetype)initWithNibName:(NSString * _Nullable)nibNameOrNil
                         bundle:(NSBundle * _Nullable)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
