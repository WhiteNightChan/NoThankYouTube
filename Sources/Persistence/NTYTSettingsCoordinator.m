#import "NTYTSettingsCoordinator.h"

#import "Core/NTYTListDefinition.h"
#import "Core/NTYTRuntimeModel.h"
#import "Core/NTYTSnapshotHolder.h"
#import "DSL/NTYTDSLParser.h"
#import "Debug/LogHelper.h"
#import "NTYTSettingsStore.h"
#import "NTYTSettingsTransferModels.h"
#import "NTYTSnapshotAssembler.h"
#import "NTYTStoredSettings.h"

static void *NTYTSettingsQueueKey = &NTYTSettingsQueueKey;

@interface NTYTMutationResult ()

- (instancetype)initWithSuccess:(BOOL)success
                        noChange:(BOOL)noChange
                       errorCode:(NTYTMutationErrorCode)errorCode
                         message:(NSString *)message;

@end

@interface NTYTImportCommitResult ()
- (instancetype)initWithStatus:(NTYTImportCommitStatus)status
                         token:(nullable NSUUID *)token
                     lifecycle:(NTYTSettingsLifecycleState)lifecycle
                         error:(nullable NSError *)error;
@end

@implementation NTYTImportCommitResult

- (instancetype)initWithStatus:(NTYTImportCommitStatus)status
                         token:(NSUUID *)token
                     lifecycle:(NTYTSettingsLifecycleState)lifecycle
                         error:(NSError *)error {
    self = [super init];
    if (self) {
        _status = status;
        _confirmationToken = token;
        _destinationLifecycle = lifecycle;
        _error = error;
    }
    return self;
}

@end

@implementation NTYTMutationResult

- (instancetype)initWithSuccess:(BOOL)success
                        noChange:(BOOL)noChange
                       errorCode:(NTYTMutationErrorCode)errorCode
                         message:(NSString *)message {
    self = [super init];
    if (self) {
        _success = success;
        _noChange = noChange;
        _errorCode = errorCode;
        _message = [message copy];
    }
    return self;
}

+ (instancetype)successResult {
    return [[self alloc] initWithSuccess:YES
                               noChange:NO
                              errorCode:NTYTMutationErrorNone
                                message:@""];
}

+ (instancetype)noChangeResult {
    return [[self alloc] initWithSuccess:YES
                               noChange:YES
                              errorCode:NTYTMutationErrorNone
                                message:@""];
}

+ (instancetype)failureWithCode:(NTYTMutationErrorCode)code message:(NSString *)message {
    return [[self alloc] initWithSuccess:NO
                               noChange:NO
                              errorCode:code
                                message:message ?: @"The operation failed."];
}

@end

@interface NTYTSettingsCoordinator ()

@property(nonatomic, strong) NTYTSettingsStore *store;
@property(nonatomic) dispatch_queue_t settingsQueue;
@property(nonatomic) NTYTSettingsLifecycleState internalLifecycleState;
@property(nonatomic, strong) NTYTStoredSettings *committedSettings;
@property(nonatomic, strong) NSUUID *destinationStateToken;

- (instancetype)initPrivate;
- (void)loadInitialStateOnQueue;
- (void)performSynchronous:(dispatch_block_t)block;
- (BOOL)mutationsAllowedOnQueue;
- (NTYTMutationResult *)commitCandidateSettingsOnQueue:(NTYTStoredSettings *)candidate;
- (BOOL)commitPreparedSettingsOnQueue:(NTYTStoredSettings *)settings
                              snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot
                                 error:(NSError * _Nullable * _Nullable)error;
- (BOOL)settings:(NTYTStoredSettings *)first
  semanticallyEqualTo:(NTYTStoredSettings *)second;
- (NTYTStoredSettings *)settingsByReplacingList:(NTYTStoredList *)list
                                          listID:(NTYTListID)listID;
- (NTYTStoredSettings *)settingsByReplacingHideMix:(BOOL)hideMix;
- (NSUInteger)findRuleID:(NSUUID *)ruleID inRules:(NSArray<NTYTStoredRule *> *)rules;
- (BOOL)rules:(NSArray<NTYTStoredRule *> *)rules
    containExpressionDuplicate:(NSString *)expression
               excludingRuleID:(nullable NSUUID *)excludedRuleID;
- (nullable NTYTMutationResult *)validateExpression:(NSString *)expression
                                          identifier:(NSUUID *)identifier;

@end

@implementation NTYTSettingsCoordinator

+ (instancetype)sharedCoordinator {
    static NTYTSettingsCoordinator *coordinator;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        coordinator = [[self alloc] initPrivate];
    });
    return coordinator;
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        _store = [[NTYTSettingsStore alloc] init];
        _settingsQueue = dispatch_queue_create("com.whitenightchan.nothankyoutube.settings", DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(_settingsQueue,
                                    NTYTSettingsQueueKey,
                                    NTYTSettingsQueueKey,
                                    NULL);
        _committedSettings = [NTYTStoredSettings emptySettings];
        _internalLifecycleState = NTYTSettingsLifecycleStateUnusable;
        _destinationStateToken = [NSUUID UUID];
        [self performSynchronous:^{
            [self loadInitialStateOnQueue];
        }];
    }
    return self;
}

- (instancetype)init {
    return [NTYTSettingsCoordinator sharedCoordinator];
}

- (void)performSynchronous:(dispatch_block_t)block {
    if (dispatch_get_specific(NTYTSettingsQueueKey)) {
        block();
    } else {
        dispatch_sync(self.settingsQueue, block);
    }
}

- (void)loadInitialStateOnQueue {
    NTYTSettingsLoadResult *loadResult = [self.store load];

    NTYTLog(@"[Settings] initial load state=%@",
            NTYTSettingsLifecycleDescription(loadResult.lifecycleState));

    if (loadResult.lifecycleState == NTYTSettingsLifecycleStateUnusable ||
        !loadResult.rawSettings) {
        self.committedSettings = [NTYTStoredSettings emptySettings];
        self.internalLifecycleState = NTYTSettingsLifecycleStateUnusable;
        [[NTYTSnapshotHolder sharedHolder]
            publishSnapshot:[NTYTRuntimeSettingsSnapshot emptySnapshot]];

        NTYTLog(@"[Settings] startup fail-open: unusable settings");

        return;
    }

    NSError *assemblyError = nil;
    NTYTSnapshotAssemblyResult *assembly =
        [NTYTSnapshotAssembler assembleRawSettings:loadResult.rawSettings
                                             error:&assemblyError];
    if (!assembly) {
        self.committedSettings = [NTYTStoredSettings emptySettings];
        self.internalLifecycleState = NTYTSettingsLifecycleStateUnusable;
        [[NTYTSnapshotHolder sharedHolder]
            publishSnapshot:[NTYTRuntimeSettingsSnapshot emptySnapshot]];

        NTYTLog(@"[Settings] snapshot assembly failed: %@",
                assemblyError.localizedDescription ?: @"<unknown>");

        return;
    }

    self.committedSettings = assembly.acceptedSettings;
    if (loadResult.lifecycleState == NTYTSettingsLifecycleStateAbsent) {
        self.internalLifecycleState = NTYTSettingsLifecycleStateAbsent;
    } else if (loadResult.lifecycleState == NTYTSettingsLifecycleStateSupportedDegraded ||
               assembly.hadDegradation) {
        self.internalLifecycleState = NTYTSettingsLifecycleStateSupportedDegraded;
    } else {
        self.internalLifecycleState = NTYTSettingsLifecycleStateSupportedValid;
    }

    [[NTYTSnapshotHolder sharedHolder] publishSnapshot:assembly.snapshot];

    NTYTLog(@"[Settings] initial snapshot published state=%@ degraded=%@",
            NTYTSettingsLifecycleDescription(self.internalLifecycleState),
            assembly.hadDegradation ? @"YES" : @"NO");
}

- (NTYTSettingsLifecycleState)lifecycleState {
    __block NTYTSettingsLifecycleState state;
    [self performSynchronous:^{
        state = self.internalLifecycleState;
    }];
    return state;
}

- (BOOL)mutationsAllowedOnQueue {
    return self.internalLifecycleState == NTYTSettingsLifecycleStateAbsent ||
           self.internalLifecycleState == NTYTSettingsLifecycleStateSupportedValid;
}

- (BOOL)mutationsAllowed {
    __block BOOL allowed = NO;
    [self performSynchronous:^{
        allowed = [self mutationsAllowedOnQueue];
    }];
    return allowed;
}

- (NSArray<NTYTStoredRule *> *)rulesForListID:(NTYTListID)listID {
    __block NSArray<NTYTStoredRule *> *rules;
    [self performSynchronous:^{
        rules = [[self.committedSettings listForID:listID].rules copy];
    }];
    return rules ?: @[];
}

- (BOOL)effectiveValueForOption:(NTYTListOptionID)optionID listID:(NTYTListID)listID {
    __block BOOL value = NO;
    [self performSynchronous:^{
        NTYTListDefinition *definition = [NTYTListDefinition definitionForListID:listID];
        if (!definition || ![definition supportsOption:optionID]) {
            value = NO;
            return;
        }
        NSNumber *override = [self.committedSettings listForID:listID]
            .optionOverrides[@(optionID)];
        value = override ? override.boolValue : [definition defaultValueForOption:optionID];
    }];
    return value;
}

- (BOOL)hideMixEnabled {
    __block BOOL enabled = NO;
    [self performSynchronous:^{
        enabled = self.committedSettings.hideMix;
    }];
    return enabled;
}

- (NTYTMutationResult *)addExpression:(NSString *)rawExpression listID:(NTYTListID)listID {
    __block NTYTMutationResult *result;
    [self performSynchronous:^{
        if (![self mutationsAllowedOnQueue]) {
            result = [NTYTMutationResult failureWithCode:NTYTMutationErrorMutationProtected
                                                 message:@"This settings file is read-only because it is degraded or unsupported."];
            return;
        }
        NTYTListDefinition *definition = [NTYTListDefinition definitionForListID:listID];
        if (!definition) {
            result = [NTYTMutationResult failureWithCode:NTYTMutationErrorInvalidRequest
                                                 message:@"The requested list is invalid."];
            return;
        }

        NSUUID *validationIdentifier =
            [[NSUUID alloc] initWithUUIDString:@"00000000-0000-0000-0000-000000000000"];
        NTYTMutationResult *validation =
            [self validateExpression:rawExpression identifier:validationIdentifier];
        if (validation) {
            result = validation;
            return;
        }

        NTYTStoredList *currentList = [self.committedSettings listForID:listID];
        if ([self rules:currentList.rules
            containExpressionDuplicate:rawExpression
                       excludingRuleID:nil]) {
            result = [NTYTMutationResult failureWithCode:NTYTMutationErrorDuplicateExpression
                                                 message:@"The same raw expression already exists in this list."];
            return;
        }

        NSMutableSet<NSUUID *> *existingIDs = [NSMutableSet set];
        for (NTYTListDefinition *otherDefinition in NTYTListDefinition.allDefinitions) {
            for (NTYTStoredRule *rule in [self.committedSettings listForID:otherDefinition.listID].rules) {
                [existingIDs addObject:rule.identifier];
            }
        }
        NSUUID *identifier = nil;
        do {
            identifier = [NSUUID UUID];
        } while ([existingIDs containsObject:identifier]);

        NSMutableArray *rules = [currentList.rules mutableCopy];
        [rules addObject:[[NTYTStoredRule alloc] initWithIdentifier:identifier
                                                        expression:rawExpression]];
        NTYTStoredList *candidateList =
            [[NTYTStoredList alloc] initWithOptionOverrides:currentList.optionOverrides
                                                      rules:rules];
        result = [self commitCandidateSettingsOnQueue:
            [self settingsByReplacingList:candidateList listID:listID]];
    }];
    return result;
}

- (NTYTMutationResult *)editRuleID:(NSUUID *)ruleID
                        expression:(NSString *)rawExpression
                            listID:(NTYTListID)listID {
    __block NTYTMutationResult *result;
    [self performSynchronous:^{
        if (![self mutationsAllowedOnQueue]) {
            result = [NTYTMutationResult failureWithCode:NTYTMutationErrorMutationProtected
                                                 message:@"This settings file is read-only because it is degraded or unsupported."];
            return;
        }
        NTYTStoredList *currentList = [self.committedSettings listForID:listID];
        NSUInteger index = [self findRuleID:ruleID inRules:currentList.rules];
        if (index == NSNotFound) {
            result = [NTYTMutationResult failureWithCode:NTYTMutationErrorRuleNotFound
                                                 message:@"The rule no longer exists."];
            return;
        }
        NTYTStoredRule *currentRule = currentList.rules[index];
        if ([currentRule.expression isEqualToString:rawExpression]) {
            result = [NTYTMutationResult noChangeResult];
            return;
        }

        NTYTMutationResult *validation =
            [self validateExpression:rawExpression identifier:ruleID];
        if (validation) {
            result = validation;
            return;
        }
        if ([self rules:currentList.rules
            containExpressionDuplicate:rawExpression
                       excludingRuleID:ruleID]) {
            result = [NTYTMutationResult failureWithCode:NTYTMutationErrorDuplicateExpression
                                                 message:@"The same raw expression already exists in this list."];
            return;
        }

        NSMutableArray *rules = [currentList.rules mutableCopy];
        rules[index] = [[NTYTStoredRule alloc] initWithIdentifier:ruleID
                                                       expression:rawExpression];
        NTYTStoredList *candidateList =
            [[NTYTStoredList alloc] initWithOptionOverrides:currentList.optionOverrides
                                                      rules:rules];
        result = [self commitCandidateSettingsOnQueue:
            [self settingsByReplacingList:candidateList listID:listID]];
    }];
    return result;
}

- (NTYTMutationResult *)deleteRuleID:(NSUUID *)ruleID listID:(NTYTListID)listID {
    return [self deleteRuleIDs:ruleID ? @[ruleID] : @[] listID:listID];
}

- (NTYTMutationResult *)deleteRuleIDs:(NSArray<NSUUID *> *)ruleIDs listID:(NTYTListID)listID {
    __block NTYTMutationResult *result;
    [self performSynchronous:^{
        if (![self mutationsAllowedOnQueue]) {
            result = [NTYTMutationResult failureWithCode:NTYTMutationErrorMutationProtected
                                                 message:@"This settings file is read-only because it is degraded or unsupported."];
            return;
        }
        if (ruleIDs.count == 0) {
            result = [NTYTMutationResult failureWithCode:NTYTMutationErrorInvalidRequest
                                                 message:@"No rules were selected."];
            return;
        }

        NTYTStoredList *currentList = [self.committedSettings listForID:listID];
        NSSet<NSUUID *> *targetIDs = [NSSet setWithArray:ruleIDs];
        if (targetIDs.count != ruleIDs.count) {
            result = [NTYTMutationResult failureWithCode:NTYTMutationErrorInvalidRequest
                                                 message:@"The delete request contains duplicate rule identifiers."];
            return;
        }
        for (NSUUID *targetID in targetIDs) {
            if ([self findRuleID:targetID inRules:currentList.rules] == NSNotFound) {
                result = [NTYTMutationResult failureWithCode:NTYTMutationErrorRuleNotFound
                                                     message:@"At least one selected rule no longer exists."];
                return;
            }
        }

        NSMutableArray<NTYTStoredRule *> *rules = [NSMutableArray array];
        for (NTYTStoredRule *rule in currentList.rules) {
            if (![targetIDs containsObject:rule.identifier]) {
                [rules addObject:rule];
            }
        }
        NTYTStoredList *candidateList =
            [[NTYTStoredList alloc] initWithOptionOverrides:currentList.optionOverrides
                                                      rules:rules];
        result = [self commitCandidateSettingsOnQueue:
            [self settingsByReplacingList:candidateList listID:listID]];
    }];
    return result;
}

- (NTYTMutationResult *)moveRuleID:(NSUUID *)ruleID
                           toIndex:(NSUInteger)destinationIndex
                            listID:(NTYTListID)listID {
    __block NTYTMutationResult *result;
    [self performSynchronous:^{
        if (![self mutationsAllowedOnQueue]) {
            result = [NTYTMutationResult failureWithCode:NTYTMutationErrorMutationProtected
                                                 message:@"This settings file is read-only because it is degraded or unsupported."];
            return;
        }
        NTYTStoredList *currentList = [self.committedSettings listForID:listID];
        NSUInteger sourceIndex = [self findRuleID:ruleID inRules:currentList.rules];
        if (sourceIndex == NSNotFound) {
            result = [NTYTMutationResult failureWithCode:NTYTMutationErrorRuleNotFound
                                                 message:@"The rule no longer exists."];
            return;
        }
        if (destinationIndex >= currentList.rules.count) {
            result = [NTYTMutationResult failureWithCode:NTYTMutationErrorInvalidRequest
                                                 message:@"The destination position is invalid."];
            return;
        }
        if (sourceIndex == destinationIndex) {
            result = [NTYTMutationResult noChangeResult];
            return;
        }

        NSMutableArray<NTYTStoredRule *> *rules = [currentList.rules mutableCopy];
        NTYTStoredRule *rule = rules[sourceIndex];
        [rules removeObjectAtIndex:sourceIndex];
        [rules insertObject:rule atIndex:destinationIndex];
        NTYTStoredList *candidateList =
            [[NTYTStoredList alloc] initWithOptionOverrides:currentList.optionOverrides
                                                      rules:rules];
        result = [self commitCandidateSettingsOnQueue:
            [self settingsByReplacingList:candidateList listID:listID]];
    }];
    return result;
}

- (NTYTMutationResult *)setEffectiveValue:(BOOL)value
                                forOption:(NTYTListOptionID)optionID
                                    listID:(NTYTListID)listID {
    __block NTYTMutationResult *result;
    [self performSynchronous:^{
        if (![self mutationsAllowedOnQueue]) {
            result = [NTYTMutationResult failureWithCode:NTYTMutationErrorMutationProtected
                                                 message:@"This settings file is read-only because it is degraded or unsupported."];
            return;
        }
        NTYTListDefinition *definition = [NTYTListDefinition definitionForListID:listID];
        if (!definition || ![definition supportsOption:optionID]) {
            result = [NTYTMutationResult failureWithCode:NTYTMutationErrorInvalidRequest
                                                 message:@"This option is not supported by the selected list."];
            return;
        }
        NTYTStoredList *currentList = [self.committedSettings listForID:listID];
        NSNumber *currentOverride = currentList.optionOverrides[@(optionID)];
        BOOL currentValue = currentOverride
            ? currentOverride.boolValue
            : [definition defaultValueForOption:optionID];
        if (currentValue == value) {
            result = [NTYTMutationResult noChangeResult];
            return;
        }

        NSMutableDictionary<NSNumber *, NSNumber *> *overrides =
            [currentList.optionOverrides mutableCopy];
        BOOL defaultValue = [definition defaultValueForOption:optionID];
        if (value == defaultValue) {
            [overrides removeObjectForKey:@(optionID)];
        } else {
            overrides[@(optionID)] = @(value);
        }
        NTYTStoredList *candidateList =
            [[NTYTStoredList alloc] initWithOptionOverrides:overrides
                                                      rules:currentList.rules];
        result = [self commitCandidateSettingsOnQueue:
            [self settingsByReplacingList:candidateList listID:listID]];
    }];
    return result;
}

- (NTYTMutationResult *)setHideMixEnabled:(BOOL)enabled {
    __block NTYTMutationResult *result;
    [self performSynchronous:^{
        if (![self mutationsAllowedOnQueue]) {
            result = [NTYTMutationResult failureWithCode:NTYTMutationErrorMutationProtected
                                                 message:@"This settings file is read-only because it is degraded or unsupported."];
            return;
        }
        if (self.committedSettings.hideMix == enabled) {
            result = [NTYTMutationResult noChangeResult];
            return;
        }
        result = [self commitCandidateSettingsOnQueue:
            [self settingsByReplacingHideMix:enabled]];
    }];
    return result;
}

- (NTYTMutationResult *)commitCandidateSettingsOnQueue:(NTYTStoredSettings *)candidate {
    NSError *snapshotError = nil;
    NTYTRuntimeSettingsSnapshot *candidateSnapshot =
        [NTYTSnapshotAssembler buildStrictSnapshotForSettings:candidate
                                                        error:&snapshotError];
    if (!candidateSnapshot) {
        NTYTLog(@"[Settings] candidate snapshot build failed: %@",
                snapshotError.localizedDescription ?: @"<unknown>");

        return [NTYTMutationResult failureWithCode:NTYTMutationErrorSnapshotBuild
                                           message:snapshotError.localizedDescription ?: @"The runtime snapshot could not be built."];
    }

    NSError *commitError = nil;
    if (![self commitPreparedSettingsOnQueue:candidate snapshot:candidateSnapshot error:&commitError]) {
        NTYTLog(@"[Settings] disk commit failed: %@",
                commitError.localizedDescription ?: @"<unknown>");

        return [NTYTMutationResult failureWithCode:NTYTMutationErrorPersistence
                                           message:commitError.localizedDescription ?: @"The settings could not be saved."];
    }

    NTYTLog(@"[Settings] mutation committed and snapshot published");

    return [NTYTMutationResult successResult];
}

- (NTYTStoredSettings *)settingsByReplacingList:(NTYTStoredList *)list
                                          listID:(NTYTListID)listID {
    NSMutableDictionary<NSNumber *, NTYTStoredList *> *lists =
        [self.committedSettings.lists mutableCopy];
    lists[@(listID)] = list;
    return [[NTYTStoredSettings alloc] initWithLists:lists
                                            hideMix:self.committedSettings.hideMix];
}

- (BOOL)commitPreparedSettingsOnQueue:(NTYTStoredSettings *)settings
                              snapshot:(NTYTRuntimeSettingsSnapshot *)snapshot
                                 error:(NSError **)error {
    // Called under settingsQueue; disk failure leaves all authoritative in-memory state intact.
    if (![self.store commitSettings:settings error:error]) {
        return NO;
    }
    self.committedSettings = settings;
    self.internalLifecycleState = NTYTSettingsLifecycleStateSupportedValid;
    self.destinationStateToken = [NSUUID UUID];
    [[NTYTSnapshotHolder sharedHolder] publishSnapshot:snapshot];
    return YES;
}

- (BOOL)settings:(NTYTStoredSettings *)first
  semanticallyEqualTo:(NTYTStoredSettings *)second {
    if (first.hideMix != second.hideMix) {
        return NO;
    }
    for (NTYTListDefinition *definition in NTYTListDefinition.allDefinitions) {
        NTYTStoredList *a = [first listForID:definition.listID];
        NTYTStoredList *b = [second listForID:definition.listID];
        if (![a.optionOverrides isEqualToDictionary:b.optionOverrides] ||
            a.rules.count != b.rules.count) {
            return NO;
        }
        for (NSUInteger index = 0; index < a.rules.count; index++) {
            NTYTStoredRule *left = a.rules[index];
            NTYTStoredRule *right = b.rules[index];
            if (![left.identifier isEqual:right.identifier] ||
                ![left.expression isEqualToString:right.expression]) {
                return NO;
            }
        }
    }
    return YES;
}

- (NTYTImportCommitResult *)commitPreparedImport:(NTYTPreparedImport *)prepared
                                confirmationToken:(NSUUID *)token {
    __block NTYTImportCommitResult *result;
    [self performSynchronous:^{
        NTYTSettingsLifecycleState state = self.internalLifecycleState;
        if (!prepared.settings || !prepared.snapshot) {
            NSError *error = [NSError errorWithDomain:NTYTSettingsStoreErrorDomain
                                                code:NTYTSettingsStoreErrorSerialization
                                            userInfo:nil];
            result = [[NTYTImportCommitResult alloc] initWithStatus:NTYTImportCommitStatusFailure
                                                               token:nil lifecycle:state error:error];
            return;
        }

        if (state != NTYTSettingsLifecycleStateAbsent &&
            ![token isEqual:self.destinationStateToken]) {
            result = [[NTYTImportCommitResult alloc]
                initWithStatus:NTYTImportCommitStatusConfirmationRequired
                         token:self.destinationStateToken lifecycle:state error:nil];
            return;
        }

        // No-op is assessed only after the latest destination is authorized.
        if (state == NTYTSettingsLifecycleStateSupportedValid &&
            [self settings:prepared.settings semanticallyEqualTo:self.committedSettings]) {
            result = [[NTYTImportCommitResult alloc] initWithStatus:NTYTImportCommitStatusNoChange
                                                               token:nil lifecycle:state error:nil];
            return;
        }

        NSError *commitError = nil;
        if (![self commitPreparedSettingsOnQueue:prepared.settings
                                         snapshot:prepared.snapshot
                                            error:&commitError]) {
            NTYTLog(@"[Settings] import disk commit failed: %@",
                    commitError.localizedDescription ?: @"<unknown>");
            result = [[NTYTImportCommitResult alloc] initWithStatus:NTYTImportCommitStatusFailure
                                                               token:nil lifecycle:state error:commitError];
            return;
        }
        result = [[NTYTImportCommitResult alloc] initWithStatus:NTYTImportCommitStatusSuccess
                                                           token:nil
                                                       lifecycle:self.internalLifecycleState
                                                           error:nil];
    }];
    return result;
}

- (NTYTExportCapture *)captureSettingsForExport {
    __block NTYTExportCapture *capture;
    [self performSynchronous:^{
        if (self.internalLifecycleState == NTYTSettingsLifecycleStateUnusable) {
            return;
        }
        capture = [[NTYTExportCapture alloc]
            initWithSettings:self.committedSettings sourceLifecycle:self.internalLifecycleState];
    }];
    return capture;
}

- (NTYTStoredSettings *)settingsByReplacingHideMix:(BOOL)hideMix {
    return [[NTYTStoredSettings alloc] initWithLists:self.committedSettings.lists
                                            hideMix:hideMix];
}

- (NSUInteger)findRuleID:(NSUUID *)ruleID inRules:(NSArray<NTYTStoredRule *> *)rules {
    if (!ruleID) {
        return NSNotFound;
    }
    for (NSUInteger index = 0; index < rules.count; index++) {
        if ([rules[index].identifier isEqual:ruleID]) {
            return index;
        }
    }
    return NSNotFound;
}

- (BOOL)rules:(NSArray<NTYTStoredRule *> *)rules
    containExpressionDuplicate:(NSString *)expression
               excludingRuleID:(NSUUID *)excludedRuleID {
    NSString *comparison = [expression stringByTrimmingCharactersInSet:
        [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    for (NTYTStoredRule *rule in rules) {
        if (excludedRuleID && [rule.identifier isEqual:excludedRuleID]) {
            continue;
        }
        NSString *existing = [rule.expression stringByTrimmingCharactersInSet:
            [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([existing isEqualToString:comparison]) {
            return YES;
        }
    }
    return NO;
}

- (NTYTMutationResult *)validateExpression:(NSString *)expression
                                  identifier:(NSUUID *)identifier {
    if (![expression isKindOfClass:[NSString class]]) {
        return [NTYTMutationResult failureWithCode:NTYTMutationErrorInvalidExpression
                                           message:@"The expression must be text."];
    }
    NSError *parseError = nil;
    NTYTRuntimeRule *rule = [NTYTDSLParser parseExpression:expression
                                                identifier:identifier
                                                     error:&parseError];
    if (!rule) {
        return [NTYTMutationResult failureWithCode:NTYTMutationErrorInvalidExpression
                                           message:parseError.localizedDescription ?: @"The expression is invalid."];
    }
    return nil;
}

@end
