#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSErrorDomain const NTYTProtobufReaderErrorDomain;

@interface NTYTProtobufReader : NSObject

+ (BOOL)validateMessageData:(NSData *)data
                      error:(NSError * _Nullable * _Nullable)error;
+ (nullable NSArray<NSData *> *)messagesAtPath:(NSArray<NSNumber *> *)fieldPath
                                       inData:(NSData *)data
                                        error:(NSError * _Nullable * _Nullable)error;
+ (nullable NSArray<NSData *> *)lengthDelimitedValuesForField:(uint32_t)fieldNumber
                                                        inData:(NSData *)data
                                                         error:(NSError * _Nullable * _Nullable)error;
+ (nullable NSArray<NSString *> *)UTF8StringsForDirectField:(uint32_t)fieldNumber
                                                     inMessage:(NSData *)message
                                                          error:(NSError * _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
