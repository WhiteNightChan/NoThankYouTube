#import <Foundation/Foundation.h>

@class NTYTMutationResult;
@class NTYTImportCommitResult;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *NTYTMutationErrorText(NTYTMutationResult *result);
FOUNDATION_EXPORT NSString *NTYTSettingsTransferErrorText(NSError *error);
FOUNDATION_EXPORT NSString *NTYTImportCommitErrorText(NTYTImportCommitResult *result);

NS_ASSUME_NONNULL_END
