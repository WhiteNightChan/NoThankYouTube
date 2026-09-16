#import <Foundation/Foundation.h>

#import "Core/NTYTTypes.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *NTYTListTitle(NTYTListID listID);
FOUNDATION_EXPORT NSString *NTYTCategoryTitle(NSUInteger categoryIndex);
FOUNDATION_EXPORT NSString *NTYTOptionTitle(NTYTListOptionID optionID);
FOUNDATION_EXPORT NSString *NTYTAddTitle(void);
FOUNDATION_EXPORT NSString *NTYTEditTitle(void);
FOUNDATION_EXPORT NSString *NTYTDeleteTitle(NSUInteger count);
FOUNDATION_EXPORT NSString *NTYTDeleteMessage(NSUInteger count, nullable NSString *expression);
FOUNDATION_EXPORT NSString *NTYTSearchPlaceholder(void);
FOUNDATION_EXPORT NSString *NTYTInputMessage(void);
FOUNDATION_EXPORT NSString *NTYTInputPlaceholder(void);
FOUNDATION_EXPORT NSString *NTYTEmptyListText(void);
FOUNDATION_EXPORT NSString *NTYTNoResultsText(void);

NS_ASSUME_NONNULL_END
