#import "NTYTProtobufReader.h"

NSErrorDomain const NTYTProtobufReaderErrorDomain = @"com.whitenightchan.nothankyoutube.protobuf";

static const uint32_t NTYTMaximumProtobufFieldNumber = 0x1fffffff;

static NSError *NTYTProtoError(NSInteger code, NSString *message) {
    return [NSError errorWithDomain:NTYTProtobufReaderErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: message}];
}

static BOOL NTYTReadVarint(const uint8_t *bytes,
                           NSUInteger length,
                           NSUInteger *offset,
                           uint64_t *value) {
    uint64_t result = 0;
    for (NSUInteger index = 0; index < 10; index++) {
        if (*offset >= length) {
            return NO;
        }
        uint8_t byte = bytes[(*offset)++];
        if (index == 9 && byte > 1) {
            return NO;
        }
        result |= ((uint64_t)(byte & 0x7f)) << (index * 7);
        if ((byte & 0x80) == 0) {
            *value = result;
            return YES;
        }
    }
    return NO;
}

static BOOL NTYTSkipWireValue(const uint8_t *bytes,
                              NSUInteger length,
                              NSUInteger *offset,
                              uint32_t fieldNumber,
                              uint8_t wireType);

static BOOL NTYTSkipGroup(const uint8_t *bytes,
                          NSUInteger length,
                          NSUInteger *offset,
                          uint32_t groupFieldNumber) {
    while (*offset < length) {
        uint64_t tag = 0;
        if (!NTYTReadVarint(bytes, length, offset, &tag) || tag == 0) {
            return NO;
        }

        uint64_t fieldValue = tag >> 3;
        uint8_t wireType = (uint8_t)(tag & 0x07);

        if (fieldValue == 0 ||
            fieldValue > NTYTMaximumProtobufFieldNumber) {
            return NO;
        }

        uint32_t fieldNumber = (uint32_t)fieldValue;

        if (wireType == 4) {
            return fieldNumber == groupFieldNumber;
        }

        if (!NTYTSkipWireValue(bytes, length, offset, fieldNumber, wireType)) {
            return NO;
        }
    }
    return NO;
}

static BOOL NTYTSkipWireValue(const uint8_t *bytes,
                              NSUInteger length,
                              NSUInteger *offset,
                              uint32_t fieldNumber,
                              uint8_t wireType) {
    uint64_t value = 0;
    switch (wireType) {
        case 0:
            return NTYTReadVarint(bytes, length, offset, &value);
        case 1:
            if (length - *offset < 8) {
                return NO;
            }
            *offset += 8;
            return YES;
        case 2:
            if (!NTYTReadVarint(bytes, length, offset, &value) ||
                value > (uint64_t)(length - *offset)) {
                return NO;
            }
            *offset += (NSUInteger)value;
            return YES;
        case 3:
            return NTYTSkipGroup(bytes, length, offset, fieldNumber);
        case 5:
            if (length - *offset < 4) {
                return NO;
            }
            *offset += 4;
            return YES;
        default:
            return NO;
    }
}

@implementation NTYTProtobufReader

+ (BOOL)validateMessageData:(NSData *)data error:(NSError **)error {
    NSArray<NSData *> *values = [self lengthDelimitedValuesForField:UINT32_MAX
                                                              inData:data
                                                               error:error];
    return values != nil;
}

+ (NSArray<NSData *> *)messagesAtPath:(NSArray<NSNumber *> *)fieldPath
                               inData:(NSData *)data
                                error:(NSError **)error {
    if (![data isKindOfClass:[NSData class]] || ![fieldPath isKindOfClass:[NSArray class]]) {
        if (error) {
            *error = NTYTProtoError(1, @"The protobuf input is invalid.");
        }
        return nil;
    }

    NSArray<NSData *> *currentMessages = @[data];
    for (NSNumber *fieldObject in fieldPath) {
        uint64_t fieldValue = fieldObject.unsignedLongLongValue;
        if (fieldValue == 0 || fieldValue > NTYTMaximumProtobufFieldNumber) {
            if (error) {
                *error = NTYTProtoError(2, @"The protobuf path contains an invalid field number.");
            }
            return nil;
        }

        NSMutableArray<NSData *> *nextMessages = [NSMutableArray array];
        for (NSData *message in currentMessages) {
            NSError *scanError = nil;
            NSArray<NSData *> *values =
                [self lengthDelimitedValuesForField:(uint32_t)fieldValue
                                             inData:message
                                              error:&scanError];
            if (!values) {
                if (error) {
                    *error = scanError;
                }
                return nil;
            }
            [nextMessages addObjectsFromArray:values];
        }
        currentMessages = nextMessages;
        if (currentMessages.count == 0) {
            break;
        }
    }
    return currentMessages;
}

+ (NSArray<NSData *> *)lengthDelimitedValuesForField:(uint32_t)fieldNumber
                                                inData:(NSData *)data
                                                 error:(NSError **)error {
    if (![data isKindOfClass:[NSData class]]) {
        if (error) {
            *error = NTYTProtoError(3, @"The protobuf message is not NSData.");
        }
        return nil;
    }

    const uint8_t *bytes = data.bytes;
    NSUInteger length = data.length;
    NSUInteger offset = 0;
    NSMutableArray<NSData *> *values = [NSMutableArray array];

    while (offset < length) {
        uint64_t tag = 0;
        if (!NTYTReadVarint(bytes, length, &offset, &tag) || tag == 0) {
            if (error) {
                *error = NTYTProtoError(4, @"A protobuf tag is malformed.");
            }
            return nil;
        }
        uint64_t fieldValue = tag >> 3;
        uint8_t wireType = (uint8_t)(tag & 0x07);
        if (fieldValue == 0 ||
            fieldValue > NTYTMaximumProtobufFieldNumber ||
            wireType == 4) {
            if (error) {
                *error = NTYTProtoError(5, @"A protobuf field is invalid in this message context.");
            }
            return nil;
        }

        if (wireType == 2) {
            uint64_t valueLength = 0;
            if (!NTYTReadVarint(bytes, length, &offset, &valueLength) ||
                valueLength > (uint64_t)(length - offset)) {
                if (error) {
                    *error = NTYTProtoError(6, @"A length-delimited protobuf field exceeds its message boundary.");
                }
                return nil;
            }
            NSRange range = NSMakeRange(offset, (NSUInteger)valueLength);
            if ((uint32_t)fieldValue == fieldNumber) {
                [values addObject:[data subdataWithRange:range]];
            }
            offset += (NSUInteger)valueLength;
            continue;
        }

        if (!NTYTSkipWireValue(bytes,
                               length,
                               &offset,
                               (uint32_t)fieldValue,
                               wireType)) {
            if (error) {
                *error = NTYTProtoError(7, @"A protobuf wire value is malformed or unsupported.");
            }
            return nil;
        }
    }
    return values;
}

+ (NSArray<NSString *> *)UTF8StringsForDirectField:(uint32_t)fieldNumber
                                             inMessage:(NSData *)message
                                                  error:(NSError **)error {
    NSArray<NSData *> *values = [self lengthDelimitedValuesForField:fieldNumber
                                                              inData:message
                                                               error:error];
    if (!values) {
        return nil;
    }

    NSMutableArray<NSString *> *strings = [NSMutableArray array];
    for (NSData *value in values) {
        NSString *string = [[NSString alloc] initWithData:value
                                                 encoding:NSUTF8StringEncoding];
        if (!string) {
            if (error) {
                *error = NTYTProtoError(8, @"A requested protobuf string is not valid UTF-8.");
            }
            return nil;
        }
        [strings addObject:string];
    }
    return strings;
}

+ (NSArray<NSNumber *> *)varintValuesForField:(uint32_t)fieldNumber
                                        inData:(NSData *)data
                                         error:(NSError **)error {
    if (![data isKindOfClass:[NSData class]] ||
        fieldNumber == 0 || fieldNumber > NTYTMaximumProtobufFieldNumber) {
        if (error) {
            *error = NTYTProtoError(9, @"The protobuf varint request is invalid.");
        }
        return nil;
    }

    const uint8_t *bytes = data.bytes;
    NSUInteger length = data.length;
    NSUInteger offset = 0;
    NSMutableArray<NSNumber *> *values = [NSMutableArray array];

    while (offset < length) {
        uint64_t tag = 0;
        if (!NTYTReadVarint(bytes, length, &offset, &tag) || tag == 0) {
            if (error) {
                *error = NTYTProtoError(10, @"A protobuf tag is malformed.");
            }
            return nil;
        }

        uint64_t fieldValue = tag >> 3;
        uint8_t wireType = (uint8_t)(tag & 0x07);
        if (fieldValue == 0 ||
            fieldValue > NTYTMaximumProtobufFieldNumber ||
            wireType == 4) {
            if (error) {
                *error = NTYTProtoError(11, @"A protobuf field is invalid in this message context.");
            }
            return nil;
        }

        if (wireType == 0) {
            uint64_t value = 0;
            if (!NTYTReadVarint(bytes, length, &offset, &value)) {
                if (error) {
                    *error = NTYTProtoError(12, @"A protobuf varint is malformed.");
                }
                return nil;
            }
            if ((uint32_t)fieldValue == fieldNumber) {
                [values addObject:@(value)];
            }
            continue;
        }

        if (!NTYTSkipWireValue(bytes,
                               length,
                               &offset,
                               (uint32_t)fieldValue,
                               wireType)) {
            if (error) {
                *error = NTYTProtoError(13, @"A protobuf wire value is malformed or unsupported.");
            }
            return nil;
        }
    }

    return values;
}

@end
