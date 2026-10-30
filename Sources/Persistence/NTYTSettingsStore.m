#import "NTYTSettingsStore.h"

#include <string.h>

#import <CoreFoundation/CoreFoundation.h>

#import "Core/NTYTListDefinition.h"
#import "NTYTStoredSettings.h"

NSErrorDomain const NTYTSettingsStoreErrorDomain = @"com.whitenightchan.nothankyoutube.persistence";

static NSError *NTYTStoreError(NTYTSettingsStoreErrorCode code,
                               NSString *message,
                               NSError *underlyingError) {
    NSMutableDictionary *details = [@{NSLocalizedDescriptionKey: message} mutableCopy];
    if (underlyingError) {
        details[NSUnderlyingErrorKey] = underlyingError;
    }
    return [NSError errorWithDomain:NTYTSettingsStoreErrorDomain
                               code:code
                           userInfo:details];
}

static BOOL NTYTIsPropertyListBoolean(id value) {
    return value && CFGetTypeID((__bridge CFTypeRef)value) == CFBooleanGetTypeID();
}

static BOOL NTYTIsIntegerVersion(id value, NSInteger expected) {
    if (![value isKindOfClass:[NSNumber class]] || NTYTIsPropertyListBoolean(value)) {
        return NO;
    }
    const char *type = [(NSNumber *)value objCType];
    if (strcmp(type, @encode(float)) == 0 || strcmp(type, @encode(double)) == 0) {
        return NO;
    }
    return [(NSNumber *)value integerValue] == expected;
}

@implementation NTYTSettingsLoadResult

- (instancetype)initWithLifecycleState:(NTYTSettingsLifecycleState)lifecycleState
                            rawSettings:(NTYTRawSettings *)rawSettings
                                  error:(NSError *)error {
    self = [super init];
    if (self) {
        _lifecycleState = lifecycleState;
        _rawSettings = rawSettings;
        _error = error;
    }
    return self;
}

@end

@interface NTYTSettingsStore ()

- (nullable NSDictionary *)dictionaryAtPath:(NSArray<NSString *> *)path
                                        root:(NSDictionary *)root
                                missingValid:(BOOL *)missingValid
                                    degraded:(BOOL *)degraded;
- (NSDictionary<NSNumber *, NSNumber *> *)readOptionOverrideMapFromListDictionary:(NSDictionary *)listDictionary
                                                              definition:(NTYTListDefinition *)definition
                                                                degraded:(BOOL *)degraded;
- (NSArray<NTYTRawRuleOccurrence *> *)readRuleOccurrenceSequenceFromListDictionary:(NSDictionary *)listDictionary
                                                          degraded:(BOOL *)degraded;
- (NSDictionary *)propertyListForSettings:(NTYTStoredSettings *)settings;

@end

@implementation NTYTSettingsStore

+ (NSString *)defaultFilePath {
    NSString *libraryDirectory =
        NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
                                            NSUserDomainMask,
                                            YES).firstObject;

    return [[libraryDirectory stringByAppendingPathComponent:@"Preferences"]
        stringByAppendingPathComponent:@"com.whitenightchan.nothankyoutube.plist"];
}

- (instancetype)init {
    return [self initWithFilePath:NTYTSettingsStore.defaultFilePath];
}

- (instancetype)initWithFilePath:(NSString *)filePath {
    self = [super init];
    if (self) {
        _filePath = [filePath copy];
    }
    return self;
}

- (NTYTSettingsLoadResult *)load {
    NSFileManager *fileManager = NSFileManager.defaultManager;
    if (![fileManager fileExistsAtPath:self.filePath]) {
        NSMutableDictionary *emptyListStateMap = [NSMutableDictionary dictionary];
        for (NTYTListDefinition *definition in NTYTListDefinition.allDefinitions) {
            emptyListStateMap[@(definition.listID)] =
                [[NTYTRawList alloc] initWithValidOptionOverrides:@{}
                                                   ruleOccurrences:@[]];
        }
        NTYTRawSettings *raw = [[NTYTRawSettings alloc] initWithAbsent:YES
                                                         baseDegraded:NO
                                                                listStateMap:emptyListStateMap
                                                              blockOptionState:[NTYTBlockOptionState allOffState]];
        return [[NTYTSettingsLoadResult alloc]
            initWithLifecycleState:NTYTSettingsLifecycleStateAbsent
                       rawSettings:raw
                             error:nil];
    }

    NSError *readError = nil;
    NSData *data = [NSData dataWithContentsOfFile:self.filePath
                                          options:0
                                            error:&readError];
    if (!data) {
        return [[NTYTSettingsLoadResult alloc]
            initWithLifecycleState:NTYTSettingsLifecycleStateUnusable
                       rawSettings:nil
                             error:NTYTStoreError(NTYTSettingsStoreErrorRead,
                                                  @"The settings file could not be read.", readError)];
    }

    NSError *plistError = nil;
    id propertyList = [NSPropertyListSerialization propertyListWithData:data
                                                                options:NSPropertyListImmutable
                                                                 format:nil
                                                                  error:&plistError];
    if (![propertyList isKindOfClass:[NSDictionary class]]) {
        return [[NTYTSettingsLoadResult alloc]
            initWithLifecycleState:NTYTSettingsLifecycleStateUnusable
                       rawSettings:nil
                             error:NTYTStoreError(NTYTSettingsStoreErrorInvalidPropertyList,
                                                  @"The settings file is not a property list dictionary.",
                                                  plistError)];
    }

    NSDictionary *root = (NSDictionary *)propertyList;
    if (!NTYTIsIntegerVersion(root[@"schemaVersion"], 1) ||
        !NTYTIsIntegerVersion(root[@"syntaxVersion"], 1)) {
        return [[NTYTSettingsLoadResult alloc]
            initWithLifecycleState:NTYTSettingsLifecycleStateUnusable
                       rawSettings:nil
                             error:NTYTStoreError(NTYTSettingsStoreErrorUnsupportedVersion,
                                                  @"The settings version is missing, invalid, or unsupported.", nil)];
    }

    __block BOOL degraded = NO;
    NSSet *allowedRootKeys = [NSSet setWithArray:@[
        @"schemaVersion", @"syntaxVersion", @"general", @"video", @"channel",
        @"post", @"playlist", @"global", @"option",
    ]];
    for (id key in root) {
        if (![key isKindOfClass:[NSString class]] || ![allowedRootKeys containsObject:key]) {
            degraded = YES;
        }
    }

    NSDictionary<NSString *, NSSet<NSString *> *> *allowedSectionKeys = @{
        @"general": [NSSet setWithArray:@[@"block", @"allow"]],
        @"video": [NSSet setWithArray:@[@"title", @"channel", @"id"]],
        @"channel": [NSSet setWithArray:@[@"block", @"allow"]],
        @"post": [NSSet setWithArray:@[@"content", @"channel", @"id"]],
        @"playlist": [NSSet setWithArray:@[@"title", @"channel", @"id"]],
        @"global": [NSSet setWithArray:@[@"block", @"allow"]],
    };
    [allowedSectionKeys enumerateKeysAndObjectsUsingBlock:^(NSString *sectionKey,
                                                            NSSet<NSString *> *allowed,
                                                            BOOL *stop) {
        id sectionObject = root[sectionKey];
        if (!sectionObject) {
            return;
        }
        if (![sectionObject isKindOfClass:[NSDictionary class]]) {
            degraded = YES;
            return;
        }
        for (id key in (NSDictionary *)sectionObject) {
            if (![key isKindOfClass:[NSString class]] || ![allowed containsObject:key]) {
                degraded = YES;
            }
        }
    }];

    // Missing and explicit false are both effective Off. Only true survives canonically.
    NSMutableDictionary<NSString *, NSNumber *> *validBlockValues = [NSMutableDictionary dictionary];
    id blockOptionObject = root[@"option"];
    if (blockOptionObject) {
        if (![blockOptionObject isKindOfClass:[NSDictionary class]]) {
            degraded = YES;
        } else {
            NSSet<NSString *> *known = [NSSet setWithArray:@[
                @"blockShorts", @"blockPost", @"blockPlaylist", @"blockMix",
                @"blockHorizontalShelf", @"blockFromYouTube",
                @"blockAdSupportedFreeMovie", @"blockCellDivider", @"blockStation",
            ]];
            NSDictionary *blockOptionMap = (NSDictionary *)blockOptionObject;
            for (id key in blockOptionMap) {
                id value = blockOptionMap[key];
                if (![key isKindOfClass:[NSString class]] ||
                    ![known containsObject:key] || !NTYTIsPropertyListBoolean(value)) {
                    degraded = YES;
                    continue;
                }
                validBlockValues[key] = @([value boolValue]);
            }
        }
    }
    NTYTBlockOptionState *blockOptionState = [[NTYTBlockOptionState alloc]
        initWithBlockShorts:[validBlockValues[@"blockShorts"] boolValue]
                 blockPost:[validBlockValues[@"blockPost"] boolValue]
             blockPlaylist:[validBlockValues[@"blockPlaylist"] boolValue]
                  blockMix:[validBlockValues[@"blockMix"] boolValue]
      blockHorizontalShelf:[validBlockValues[@"blockHorizontalShelf"] boolValue]
          blockFromYouTube:[validBlockValues[@"blockFromYouTube"] boolValue]
 blockAdSupportedFreeMovie:[validBlockValues[@"blockAdSupportedFreeMovie"] boolValue]
          blockCellDivider:[validBlockValues[@"blockCellDivider"] boolValue]
              blockStation:[validBlockValues[@"blockStation"] boolValue]];

    NSMutableDictionary<NSNumber *, NTYTRawList *> *rawListStateMap = [NSMutableDictionary dictionary];
    for (NTYTListDefinition *definition in NTYTListDefinition.allDefinitions) {
        BOOL missingValid = NO;
        NSDictionary *listDictionary = [self dictionaryAtPath:definition.storagePath
                                                         root:root
                                                 missingValid:&missingValid
                                                     degraded:&degraded];
        if (!listDictionary) {
            rawListStateMap[@(definition.listID)] =
                [[NTYTRawList alloc] initWithValidOptionOverrides:@{}
                                                   ruleOccurrences:@[]];
            continue;
        }

        NSSet *allowedListKeys = definition.supportedOptionIDs.count > 0
            ? [NSSet setWithArray:@[@"option", @"rule"]]
            : [NSSet setWithObject:@"rule"];
        for (id key in listDictionary) {
            if (![key isKindOfClass:[NSString class]] || ![allowedListKeys containsObject:key]) {
                degraded = YES;
            }
        }

        NSDictionary *optionOverrideMap = [self readOptionOverrideMapFromListDictionary:listDictionary
                                                           definition:definition
                                                             degraded:&degraded];
        NSArray *ruleSequence = [self readRuleOccurrenceSequenceFromListDictionary:listDictionary
                                                  degraded:&degraded];
        rawListStateMap[@(definition.listID)] =
            [[NTYTRawList alloc] initWithValidOptionOverrides:optionOverrideMap
                                               ruleOccurrences:ruleSequence];
    }

    NTYTRawSettings *rawSettings =
        [[NTYTRawSettings alloc] initWithAbsent:NO
                                   baseDegraded:degraded
                                          listStateMap:rawListStateMap
                                        blockOptionState:blockOptionState];
    NTYTSettingsLifecycleState state = degraded
        ? NTYTSettingsLifecycleStateSupportedDegraded
        : NTYTSettingsLifecycleStateSupportedValid;
    return [[NTYTSettingsLoadResult alloc] initWithLifecycleState:state
                                                      rawSettings:rawSettings
                                                            error:nil];
}

- (NSDictionary *)dictionaryAtPath:(NSArray<NSString *> *)path
                               root:(NSDictionary *)root
                       missingValid:(BOOL *)missingValid
                           degraded:(BOOL *)degraded {
    id current = root;
    for (NSString *component in path) {
        if (![current isKindOfClass:[NSDictionary class]]) {
            *degraded = YES;
            return nil;
        }
        id next = [(NSDictionary *)current objectForKey:component];
        if (!next) {
            if (missingValid) {
                *missingValid = YES;
            }
            return nil;
        }
        if (![next isKindOfClass:[NSDictionary class]]) {
            *degraded = YES;
            return nil;
        }
        current = next;
    }
    return current;
}

- (NSDictionary<NSNumber *,NSNumber *> *)readOptionOverrideMapFromListDictionary:(NSDictionary *)listDictionary
                                                              definition:(NTYTListDefinition *)definition
                                                                degraded:(BOOL *)degraded {
    id optionOverrideObject = listDictionary[@"option"];
    if (!optionOverrideObject) {
        return @{};
    }
    if (![optionOverrideObject isKindOfClass:[NSDictionary class]] ||
        definition.supportedOptionIDs.count == 0) {
        *degraded = YES;
        return @{};
    }

    NSDictionary *optionOverrideMap = (NSDictionary *)optionOverrideObject;
    NSDictionary<NSString *, NSNumber *> *optionMap = @{
        @"caseSensitive": @(NTYTListOptionIDCaseSensitive),
        @"exactMatch": @(NTYTListOptionIDExactMatch),
    };
    NSMutableDictionary<NSNumber *, NSNumber *> *valid = [NSMutableDictionary dictionary];
    for (id key in optionOverrideMap) {
        NSNumber *optionID = [key isKindOfClass:[NSString class]] ? optionMap[key] : nil;
        id value = optionOverrideMap[key];
        if (!optionID ||
            ![definition.supportedOptionIDs containsObject:optionID] ||
            !NTYTIsPropertyListBoolean(value)) {
            *degraded = YES;
            continue;
        }

        BOOL overrideValue = [(NSNumber *)value boolValue];
        NTYTListOptionID typedOptionID = (NTYTListOptionID)optionID.integerValue;
        if (overrideValue != [definition defaultValueForOption:typedOptionID]) {
            valid[optionID] = @(overrideValue);
        }
    }
    return valid;
}

- (NSArray<NTYTRawRuleOccurrence *> *)readRuleOccurrenceSequenceFromListDictionary:(NSDictionary *)listDictionary
                                                          degraded:(BOOL *)degraded {
    id ruleSequenceObject = listDictionary[@"rule"];
    if (!ruleSequenceObject) {
        return @[];
    }
    if (![ruleSequenceObject isKindOfClass:[NSArray class]]) {
        *degraded = YES;
        return @[];
    }

    NSMutableArray<NTYTRawRuleOccurrence *> *occurrences = [NSMutableArray array];
    NSSet *allowedRuleKeys = [NSSet setWithArray:@[@"id", @"expression"]];
    for (id object in (NSArray *)ruleSequenceObject) {
        if (![object isKindOfClass:[NSDictionary class]]) {
            *degraded = YES;
            [occurrences addObject:[[NTYTRawRuleOccurrence alloc]
                initWithRawIdentifier:nil rawExpression:nil]];
            continue;
        }
        NSDictionary *record = (NSDictionary *)object;
        for (id key in record) {
            if (![key isKindOfClass:[NSString class]] || ![allowedRuleKeys containsObject:key]) {
                *degraded = YES;
            }
        }
        [occurrences addObject:[[NTYTRawRuleOccurrence alloc]
            initWithRawIdentifier:record[@"id"]
                    rawExpression:record[@"expression"]]];
    }
    return occurrences;
}

- (BOOL)commitSettings:(NTYTStoredSettings *)settings error:(NSError **)error {
    NSDictionary *propertyList = [self propertyListForSettings:settings];
    NSError *serializationError = nil;
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:propertyList
                                                              format:NSPropertyListXMLFormat_v1_0
                                                             options:0
                                                               error:&serializationError];
    if (!data) {
        if (error) {
            *error = NTYTStoreError(NTYTSettingsStoreErrorSerialization,
                                    @"The settings could not be serialized.", serializationError);
        }
        return NO;
    }

    NSString *directory = [self.filePath stringByDeletingLastPathComponent];
    NSError *directoryError = nil;
    if (![NSFileManager.defaultManager createDirectoryAtPath:directory
                                withIntermediateDirectories:YES
                                                 attributes:nil
                                                      error:&directoryError]) {
        if (error) {
            *error = NTYTStoreError(NTYTSettingsStoreErrorWrite,
                                    @"The settings directory could not be created.", directoryError);
        }
        return NO;
    }

    NSError *writeError = nil;
    BOOL wrote = [data writeToFile:self.filePath
                           options:NSDataWritingAtomic
                             error:&writeError];
    if (!wrote && error) {
        *error = NTYTStoreError(NTYTSettingsStoreErrorWrite,
                                @"The settings could not be written.", writeError);
    }
    return wrote;
}

- (NSDictionary *)propertyListForSettings:(NTYTStoredSettings *)settings {
    NSMutableDictionary *root = [@{
        @"schemaVersion": @1,
        @"syntaxVersion": @1,
    } mutableCopy];

    NSDictionary<NSNumber *, NSString *> *optionKeys = @{
        @(NTYTListOptionIDCaseSensitive): @"caseSensitive",
        @(NTYTListOptionIDExactMatch): @"exactMatch",
    };
    for (NTYTListDefinition *definition in NTYTListDefinition.allDefinitions) {
        NTYTStoredList *storedList = [settings listForID:definition.listID];
        if (storedList.optionOverrides.count == 0 && storedList.ruleSequence.count == 0) {
            continue;
        }
        NSMutableDictionary *listDictionary = [NSMutableDictionary dictionary];

        if (storedList.optionOverrides.count > 0) {
            NSMutableDictionary *optionOverrideMap = [NSMutableDictionary dictionary];
            [storedList.optionOverrides enumerateKeysAndObjectsUsingBlock:^(NSNumber *optionID,
                                                                            NSNumber *value,
                                                                            BOOL *stop) {
                NSString *key = optionKeys[optionID];
                if (key) {
                    optionOverrideMap[key] = @([value boolValue]);
                }
            }];
            if (optionOverrideMap.count > 0) {
                listDictionary[@"option"] = optionOverrideMap;
            }
        }

        if (storedList.ruleSequence.count > 0) {
            NSMutableArray *ruleSequence = [NSMutableArray arrayWithCapacity:storedList.ruleSequence.count];
            for (NTYTStoredRule *rule in storedList.ruleSequence) {
                [ruleSequence addObject:@{
                    @"id": rule.identifier.UUIDString,
                    @"expression": rule.expression,
                }];
            }
            listDictionary[@"rule"] = ruleSequence;
        }

        NSMutableDictionary *section = root[definition.storagePath[0]];
        if (!section) {
            section = [NSMutableDictionary dictionary];
            root[definition.storagePath[0]] = section;
        }
        section[definition.storagePath[1]] = listDictionary;
    }

    NTYTBlockOptionState *state = settings.blockOptionState;
    NSMutableDictionary *blockOptionMap = [NSMutableDictionary dictionary];
    if (state.blockShorts) blockOptionMap[@"blockShorts"] = @YES;
    if (state.blockPost) blockOptionMap[@"blockPost"] = @YES;
    if (state.blockPlaylist) blockOptionMap[@"blockPlaylist"] = @YES;
    if (state.blockMix) blockOptionMap[@"blockMix"] = @YES;
    if (state.blockHorizontalShelf) blockOptionMap[@"blockHorizontalShelf"] = @YES;
    if (state.blockFromYouTube) blockOptionMap[@"blockFromYouTube"] = @YES;
    if (state.blockAdSupportedFreeMovie) blockOptionMap[@"blockAdSupportedFreeMovie"] = @YES;
    if (state.blockCellDivider) blockOptionMap[@"blockCellDivider"] = @YES;
    if (state.blockStation) blockOptionMap[@"blockStation"] = @YES;
    if (blockOptionMap.count > 0) root[@"option"] = blockOptionMap;
    return root;
}

@end
