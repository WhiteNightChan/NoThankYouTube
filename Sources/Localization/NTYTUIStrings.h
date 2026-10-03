#import <Foundation/Foundation.h>

#import "Core/NTYTTypes.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *NTYTAppName(void);
FOUNDATION_EXPORT NSString *NTYTListTitle(NTYTListID listID);
FOUNDATION_EXPORT NSString *NTYTCategoryTitle(NSUInteger categoryIndex);
FOUNDATION_EXPORT NSString *NTYTOptionTitle(NTYTListOptionID optionID);
FOUNDATION_EXPORT NSString *NTYTSettingsLifecycleText(NTYTSettingsLifecycleState state);
FOUNDATION_EXPORT NSString *NTYTReadOnlyText(NTYTSettingsLifecycleState state);

FOUNDATION_EXPORT NSString *NTYTOKTitle(void);
FOUNDATION_EXPORT NSString *NTYTSaveTitle(void);
FOUNDATION_EXPORT NSString *NTYTCancelTitle(void);
FOUNDATION_EXPORT NSString *NTYTDeleteActionTitle(void);
FOUNDATION_EXPORT NSString *NTYTEditActionTitle(void);
FOUNDATION_EXPORT NSString *NTYTDoneTitle(void);
FOUNDATION_EXPORT NSString *NTYTSelectAllTitle(void);
FOUNDATION_EXPORT NSString *NTYTDeselectAllTitle(void);
FOUNDATION_EXPORT NSString *NTYTHideMixTitle(void);

FOUNDATION_EXPORT NSString *NTYTAddTitle(void);
FOUNDATION_EXPORT NSString *NTYTEditTitle(void);
FOUNDATION_EXPORT NSString *NTYTDeleteTitle(NSUInteger count);
FOUNDATION_EXPORT NSString *NTYTDeleteMessage(NSUInteger count, NSString * _Nullable expression);
FOUNDATION_EXPORT NSString *NTYTSearchPlaceholder(void);
FOUNDATION_EXPORT NSString *NTYTInputMessage(void);
FOUNDATION_EXPORT NSString *NTYTInputPlaceholder(void);
FOUNDATION_EXPORT NSString *NTYTEmptyListText(void);
FOUNDATION_EXPORT NSString *NTYTNoResultsText(void);
FOUNDATION_EXPORT NSString *NTYTRuleCountText(NSUInteger count);
FOUNDATION_EXPORT NSString *NTYTCopiedRuleText(NSString *expression);
FOUNDATION_EXPORT NSString *NTYTSelectionStaleText(void);

FOUNDATION_EXPORT NSString *NTYTImportSettingsTitle(void);
FOUNDATION_EXPORT NSString *NTYTExportSettingsTitle(void);
FOUNDATION_EXPORT NSString *NTYTImportSuccessText(void);
FOUNDATION_EXPORT NSString *NTYTImportNoChangesText(void);
FOUNDATION_EXPORT NSString *NTYTImportReplaceTitle(void);
FOUNDATION_EXPORT NSString *NTYTImportReplaceMessage(void);
FOUNDATION_EXPORT NSString *NTYTImportReplaceActionTitle(void);
FOUNDATION_EXPORT NSString *NTYTImportPickerUnavailableText(void);
FOUNDATION_EXPORT NSString *NTYTImportInvalidSelectionText(void);
FOUNDATION_EXPORT NSString *NTYTImportConfirmationUnavailableText(void);
FOUNDATION_EXPORT NSString *NTYTExportSuccessText(void);
FOUNDATION_EXPORT NSString *NTYTExportUnavailableText(void);
FOUNDATION_EXPORT NSString *NTYTExportSalvageNoticeText(void);
FOUNDATION_EXPORT NSString *NTYTExportPickerUnavailableText(void);

NS_ASSUME_NONNULL_END
