#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LogHelper : NSObject

+ (void)appendLine:(NSString *)line;
+ (void)clearLogFile;
+ (NSString *)logFilePath;

@end

NS_ASSUME_NONNULL_END

#define NTYTLog(fmt, ...) \
    do { \
        @try { \
            [LogHelper appendLine: \
                [NSString stringWithFormat:(fmt), ##__VA_ARGS__]]; \
        } @catch (__unused NSException *exception) { \
        } \
    } while (0)