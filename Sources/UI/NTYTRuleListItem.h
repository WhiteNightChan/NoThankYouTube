#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NTYTRuleListItem : NSObject

@property(nonatomic, strong, readonly) NSUUID *identifier;
@property(nonatomic, copy, readonly) NSString *text;

- (instancetype)initWithIdentifier:(NSUUID *)identifier
                               text:(NSString *)text NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
