#import "NTYTRuleListItem.h"

@implementation NTYTRuleListItem

- (instancetype)initWithIdentifier:(NSUUID *)identifier text:(NSString *)text {
    self = [super init];
    if (self) {
        _identifier = identifier;
        _text = [text copy];
    }
    return self;
}

@end
