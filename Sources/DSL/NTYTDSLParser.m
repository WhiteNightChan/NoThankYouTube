#import "NTYTDSLParser.h"

#import "Core/NTYTRuntimeModel.h"

NSErrorDomain const NTYTDSLErrorDomain = @"com.whitenightchan.nothankyoutube.dsl";

static NSError *NTYTDSLError(NTYTDSLErrorCode code, NSString *message) {
    return [NSError errorWithDomain:NTYTDSLErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: message}];
}

static BOOL NTYTIsHorizontalWhitespace(unichar character) {
    return character == ' ' || character == '\t' ||
        [[NSCharacterSet whitespaceCharacterSet] characterIsMember:character];
}

static NSString *NTYTTrimHorizontalWhitespace(NSString *string) {
    return [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

static BOOL NTYTContainsNewline(NSString *string) {
    return [string rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]].location != NSNotFound;
}

static BOOL NTYTStartsWithAtIndex(NSString *string, NSString *prefix, NSUInteger index) {
    if (index > string.length || prefix.length > string.length - index) {
        return NO;
    }
    return [[string substringWithRange:NSMakeRange(index, prefix.length)] isEqualToString:prefix];
}

@interface NTYTRegexParseResult : NSObject

@property(nonatomic, copy) NSString *pattern;
@property(nonatomic) NSRegularExpressionOptions options;
@property(nonatomic) NSUInteger consumedLength;

@end


@implementation NTYTRegexParseResult
@end

@interface NTYTDSLParser ()

+ (nullable NTYTModifier *)parseModifierInExpression:(NSString *)expression
                                             atIndex:(NSUInteger)index
                                           nextIndex:(NSUInteger *)nextIndex
                                               error:(NSError **)error;
+ (nullable NTYTMatcherExpression *)parseMatcherExpression:(NSString *)source
                                                      error:(NSError **)error;
+ (nullable NTYTRegexParseResult *)parseRegexLiteral:(NSString *)literal
                                                error:(NSError **)error;
+ (nullable NSString *)unescapePlainText:(NSString *)source
                                    error:(NSError **)error;
+ (BOOL)plainSourceContainsUnescapedModifierToken:(NSString *)source;
+ (nullable NSNumber *)regexTokenEndInExpression:(NSString *)expression
                                        fromIndex:(NSUInteger)index
                                            error:(NSError **)error;

@end

@implementation NTYTDSLParser

+ (NTYTRuntimeRule *)parseExpression:(NSString *)rawExpression
                           identifier:(NSUUID *)identifier
                                error:(NSError **)error {
    if (![rawExpression isKindOfClass:[NSString class]] ||
        ![identifier isKindOfClass:[NSUUID class]]) {
        if (error) {
            *error = NTYTDSLError(NTYTDSLErrorEmptyExpression,
                                  @"The rule expression or identifier is invalid.");
        }
        return nil;
    }

    if (NTYTContainsNewline(rawExpression)) {
        if (error) {
            *error = NTYTDSLError(NTYTDSLErrorNewline,
                                  @"A rule must be a single line.");
        }
        return nil;
    }

    NSString *expression = NTYTTrimHorizontalWhitespace(rawExpression);
    if (expression.length == 0) {
        if (error) {
            *error = NTYTDSLError(NTYTDSLErrorEmptyExpression,
                                  @"A main matcher is required.");
        }
        return nil;
    }

    NSMutableArray<NTYTModifier *> *modifiers = [NSMutableArray array];
    NSUInteger cursor = 0;

    while (NTYTStartsWithAtIndex(expression, @"${", cursor)) {
        NSUInteger nextIndex = NSNotFound;
        NTYTModifier *modifier = [self parseModifierInExpression:expression
                                                         atIndex:cursor
                                                       nextIndex:&nextIndex
                                                           error:error];
        if (!modifier) {
            return nil;
        }
        [modifiers addObject:modifier];
        cursor = nextIndex;

        if (cursor >= expression.length) {
            if (error) {
                *error = NTYTDSLError(NTYTDSLErrorMissingMainMatcher,
                                      @"A main matcher is required after the modifiers.");
            }
            return nil;
        }

        if (!NTYTIsHorizontalWhitespace([expression characterAtIndex:cursor])) {
            if (error) {
                *error = NTYTDSLError(NTYTDSLErrorMissingSeparator,
                                      @"A modifier must be followed by horizontal whitespace.");
            }
            return nil;
        }

        while (cursor < expression.length &&
               NTYTIsHorizontalWhitespace([expression characterAtIndex:cursor])) {
            cursor++;
        }

        if (cursor >= expression.length) {
            if (error) {
                *error = NTYTDSLError(NTYTDSLErrorMissingMainMatcher,
                                      @"A main matcher is required after the modifiers.");
            }
            return nil;
        }
    }

    NSString *mainSource = [expression substringFromIndex:cursor];
    NTYTMatcherExpression *mainMatcher =
        [self parseMatcherExpression:mainSource error:error];
    if (!mainMatcher) {
        return nil;
    }

    return [[NTYTRuntimeRule alloc] initWithIdentifier:identifier
                                            mainMatcher:mainMatcher
                                              modifiers:modifiers];
}

+ (NTYTModifier *)parseModifierInExpression:(NSString *)expression
                                     atIndex:(NSUInteger)index
                                   nextIndex:(NSUInteger *)nextIndex
                                       error:(NSError **)error {
    NSUInteger cursor = index + 2;
    BOOL modifierNegative = NO;

    if (cursor < expression.length && [expression characterAtIndex:cursor] == '!') {
        modifierNegative = YES;
        cursor++;
    }

    NSUInteger nameStart = cursor;
    while (cursor < expression.length) {
        unichar character = [expression characterAtIndex:cursor];
        BOOL isASCIIAlpha = (character >= 'a' && character <= 'z') ||
                            (character >= 'A' && character <= 'Z');
        if (!isASCIIAlpha) {
            break;
        }
        cursor++;
    }

    if (cursor == nameStart) {
        if (error) {
            *error = NTYTDSLError(NTYTDSLErrorMalformedModifier,
                                  @"The modifier name is malformed.");
        }
        return nil;
    }

    NSString *name = [expression substringWithRange:NSMakeRange(nameStart, cursor - nameStart)];
    BOOL isChannel = [name isEqualToString:@"ch"];
    BOOL isContent = [name isEqualToString:@"ctn"];
    BOOL isVideo = [name isEqualToString:@"video"];
    if (!isChannel && !isContent && !isVideo) {
        if (error) {
            *error = NTYTDSLError(NTYTDSLErrorUnknownModifier,
                                  [NSString stringWithFormat:@"Unknown modifier: %@", name]);
        }
        return nil;
    }

    if (isVideo) {
        if (cursor >= expression.length || [expression characterAtIndex:cursor] != '}') {
            if (error) {
                *error = NTYTDSLError(NTYTDSLErrorUnexpectedModifierValue,
                                      @"The video modifier does not accept a value.");
            }
            return nil;
        }
        if (nextIndex) {
            *nextIndex = cursor + 1;
        }
        return [NTYTModifier videoModifierNegative:modifierNegative];
    }

    if (cursor >= expression.length || [expression characterAtIndex:cursor] != ':') {
        if (error) {
            *error = NTYTDSLError(NTYTDSLErrorMissingModifierValue,
                                  @"The ch and ctn modifiers require a value.");
        }
        return nil;
    }
    cursor++;

    NSUInteger valueStart = cursor;
    while (valueStart < expression.length &&
           NTYTIsHorizontalWhitespace([expression characterAtIndex:valueStart])) {
        valueStart++;
    }

    if (valueStart >= expression.length) {
        if (error) {
            *error = NTYTDSLError(NTYTDSLErrorMissingModifierValue,
                                  @"The modifier value is missing.");
        }
        return nil;
    }

    NSUInteger probe = valueStart;
    if ([expression characterAtIndex:probe] == '!') {
        probe++;
        if (probe >= expression.length ||
            NTYTIsHorizontalWhitespace([expression characterAtIndex:probe])) {
            if (error) {
                *error = NTYTDSLError(NTYTDSLErrorMalformedModifier,
                                      @"A negative marker must be attached to its matcher.");
            }
            return nil;
        }
    }

    NSUInteger closeIndex = NSNotFound;
    NSUInteger valueEnd = NSNotFound;

    if (probe < expression.length && [expression characterAtIndex:probe] == '/') {
        NSNumber *regexEndNumber = [self regexTokenEndInExpression:expression
                                                         fromIndex:probe
                                                             error:error];
        if (!regexEndNumber) {
            return nil;
        }
        valueEnd = regexEndNumber.unsignedIntegerValue;
        closeIndex = valueEnd;
        while (closeIndex < expression.length &&
               NTYTIsHorizontalWhitespace([expression characterAtIndex:closeIndex])) {
            closeIndex++;
        }
        if (closeIndex >= expression.length ||
            [expression characterAtIndex:closeIndex] != '}') {
            if (error) {
                *error = NTYTDSLError(NTYTDSLErrorMalformedModifier,
                                      @"The regex modifier value has no closing brace.");
            }
            return nil;
        }
    } else {
        BOOL escaped = NO;
        for (NSUInteger i = valueStart; i < expression.length; i++) {
            unichar character = [expression characterAtIndex:i];
            if (escaped) {
                escaped = NO;
                continue;
            }
            if (character == '\\') {
                escaped = YES;
                continue;
            }
            if (character == '}') {
                closeIndex = i;
                valueEnd = i;
                break;
            }
        }
        if (closeIndex == NSNotFound) {
            if (error) {
                *error = NTYTDSLError(NTYTDSLErrorMalformedModifier,
                                      @"The modifier has no closing brace.");
            }
            return nil;
        }
    }

    NSString *valueSource =
        [expression substringWithRange:NSMakeRange(cursor, valueEnd - cursor)];
    valueSource = NTYTTrimHorizontalWhitespace(valueSource);
    if (valueSource.length == 0) {
        if (error) {
            *error = NTYTDSLError(NTYTDSLErrorMissingModifierValue,
                                  @"The modifier value is empty.");
        }
        return nil;
    }

    NTYTMatcherExpression *matcherExpression =
        [self parseMatcherExpression:valueSource error:error];
    if (!matcherExpression) {
        return nil;
    }

    if (nextIndex) {
        *nextIndex = closeIndex + 1;
    }
    NTYTModifierKind kind = isChannel ? NTYTModifierKindChannel : NTYTModifierKindContent;
    return [NTYTModifier matcherModifierWithKind:kind
                                        negative:modifierNegative
                               matcherExpression:matcherExpression];
}

+ (NTYTMatcherExpression *)parseMatcherExpression:(NSString *)source
                                             error:(NSError **)error {
    NSString *token = NTYTTrimHorizontalWhitespace(source);
    if (token.length == 0) {
        if (error) {
            *error = NTYTDSLError(NTYTDSLErrorMissingMainMatcher,
                                  @"A matcher is required.");
        }
        return nil;
    }

    BOOL negative = NO;
    if ([token characterAtIndex:0] == '!') {
        negative = YES;
        if (token.length == 1 || NTYTIsHorizontalWhitespace([token characterAtIndex:1])) {
            if (error) {
                *error = NTYTDSLError(NTYTDSLErrorMalformedEscape,
                                      @"A negative marker must be attached to its matcher.");
            }
            return nil;
        }
        token = [token substringFromIndex:1];
    }

    NTYTMatcher *matcher = nil;
    if ([token characterAtIndex:0] == '/') {
        NTYTRegexParseResult *regexResult = [self parseRegexLiteral:token error:error];
        if (!regexResult) {
            return nil;
        }
        NSError *compileError = nil;
        NSRegularExpression *regularExpression =
            [NSRegularExpression regularExpressionWithPattern:regexResult.pattern
                                                       options:regexResult.options
                                                         error:&compileError];
        if (!regularExpression) {
            if (error) {
                NSString *message = compileError.localizedDescription ?: @"The regex could not be compiled.";
                *error = NTYTDSLError(NTYTDSLErrorRegexCompile, message);
            }
            return nil;
        }
        matcher = [NTYTMatcher regexMatcherWithExpression:regularExpression];
    } else {
        if ([self plainSourceContainsUnescapedModifierToken:token]) {
            if (error) {
                *error = NTYTDSLError(NTYTDSLErrorModifierAfterMain,
                                      @"Modifiers are allowed only before the main matcher.");
            }
            return nil;
        }
        NSString *plainText = [self unescapePlainText:token error:error];
        if (!plainText) {
            return nil;
        }
        matcher = [NTYTMatcher plainMatcherWithText:plainText];
    }

    return [[NTYTMatcherExpression alloc] initWithMatcher:matcher negative:negative];
}

+ (NTYTRegexParseResult *)parseRegexLiteral:(NSString *)literal
                                       error:(NSError **)error {
    if (literal.length < 2 || [literal characterAtIndex:0] != '/') {
        if (error) {
            *error = NTYTDSLError(NTYTDSLErrorMalformedRegex,
                                  @"The regex literal is malformed.");
        }
        return nil;
    }

    NSMutableString *pattern = [NSMutableString string];
    NSUInteger cursor = 1;
    BOOL foundClosingSlash = NO;

    while (cursor < literal.length) {
        unichar character = [literal characterAtIndex:cursor];
        if (character == '\\') {
            if (cursor + 1 >= literal.length) {
                if (error) {
                    *error = NTYTDSLError(NTYTDSLErrorMalformedRegex,
                                          @"The regex ends with an incomplete escape.");
                }
                return nil;
            }
            unichar next = [literal characterAtIndex:cursor + 1];
            if (next == '/') {
                [pattern appendString:@"/"];
            } else {
                [pattern appendString:@"\\"];
                [pattern appendFormat:@"%C", next];
            }
            cursor += 2;
            continue;
        }
        if (character == '/') {
            foundClosingSlash = YES;
            cursor++;
            break;
        }
        [pattern appendFormat:@"%C", character];
        cursor++;
    }

    if (!foundClosingSlash) {
        if (error) {
            *error = NTYTDSLError(NTYTDSLErrorMalformedRegex,
                                  @"The regex has no closing delimiter.");
        }
        return nil;
    }
    if (pattern.length == 0) {
        if (error) {
            *error = NTYTDSLError(NTYTDSLErrorEmptyRegex,
                                  @"An empty regex is not allowed; use /.*/ explicitly.");
        }
        return nil;
    }

    BOOL hasIFlag = NO;
    while (cursor < literal.length) {
        unichar flag = [literal characterAtIndex:cursor];
        if (flag != 'i') {
            if (error) {
                *error = NTYTDSLError(NTYTDSLErrorUnsupportedRegexFlag,
                                      [NSString stringWithFormat:@"Unsupported regex flag: %C", flag]);
            }
            return nil;
        }
        if (hasIFlag) {
            if (error) {
                *error = NTYTDSLError(NTYTDSLErrorDuplicateRegexFlag,
                                      @"The regex flag i is duplicated.");
            }
            return nil;
        }
        hasIFlag = YES;
        cursor++;
    }

    NTYTRegexParseResult *result = [NTYTRegexParseResult new];
    result.pattern = pattern;
    result.options = hasIFlag ? NSRegularExpressionCaseInsensitive : 0;
    result.consumedLength = cursor;
    return result;
}

+ (NSNumber *)regexTokenEndInExpression:(NSString *)expression
                                fromIndex:(NSUInteger)index
                                    error:(NSError **)error {
    NSUInteger cursor = index + 1;
    BOOL foundClosingSlash = NO;
    while (cursor < expression.length) {
        unichar character = [expression characterAtIndex:cursor];
        if (character == '\\') {
            if (cursor + 1 >= expression.length) {
                if (error) {
                    *error = NTYTDSLError(NTYTDSLErrorMalformedRegex,
                                          @"The regex ends with an incomplete escape.");
                }
                return nil;
            }
            cursor += 2;
            continue;
        }
        if (character == '/') {
            foundClosingSlash = YES;
            cursor++;
            break;
        }
        cursor++;
    }
    if (!foundClosingSlash) {
        if (error) {
            *error = NTYTDSLError(NTYTDSLErrorMalformedRegex,
                                  @"The regex has no closing delimiter.");
        }
        return nil;
    }

    while (cursor < expression.length) {
        unichar character = [expression characterAtIndex:cursor];
        if (character == '}' || NTYTIsHorizontalWhitespace(character)) {
            break;
        }
        cursor++;
    }
    return @(cursor);
}

+ (NSString *)unescapePlainText:(NSString *)source error:(NSError **)error {
    NSMutableString *result = [NSMutableString string];
    for (NSUInteger i = 0; i < source.length; i++) {
        unichar character = [source characterAtIndex:i];
        if (character != '\\') {
            [result appendFormat:@"%C", character];
            continue;
        }
        if (i + 1 >= source.length) {
            if (error) {
                *error = NTYTDSLError(NTYTDSLErrorMalformedEscape,
                                      @"The plain matcher ends with an incomplete escape.");
            }
            return nil;
        }
        i++;
        [result appendFormat:@"%C", [source characterAtIndex:i]];
    }
    return result;
}

+ (BOOL)plainSourceContainsUnescapedModifierToken:(NSString *)source {
    for (NSUInteger i = 0; i + 1 < source.length; i++) {
        unichar character = [source characterAtIndex:i];
        if (character == '\\') {
            i++;
            continue;
        }
        if (character == '$' && [source characterAtIndex:i + 1] == '{') {
            return YES;
        }
    }
    return NO;
}

@end
