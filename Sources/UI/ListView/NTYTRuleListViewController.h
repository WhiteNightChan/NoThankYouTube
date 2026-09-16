#import <UIKit/UIKit.h>

#import "Core/NTYTTypes.h"

NS_ASSUME_NONNULL_BEGIN

@interface NTYTRuleListViewController : UITableViewController

@property(nonatomic, readonly) NTYTListID listID;
@property(nonatomic, copy, readonly) NSString *titleText;

- (instancetype)initWithListID:(NTYTListID)listID
                          title:(NSString *)title NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithStyle:(UITableViewStyle)style NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
