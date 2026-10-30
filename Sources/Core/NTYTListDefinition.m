#import "NTYTListDefinition.h"

@implementation NTYTMatchOptionState

- (instancetype)initWithCaseSensitive:(BOOL)caseSensitive
                            exactMatch:(BOOL)exactMatch {
    self = [super init];
    if (self) {
        _caseSensitive = caseSensitive;
        _exactMatch = exactMatch;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

@end

@interface NTYTListDefinition ()

- (instancetype)initWithListID:(NTYTListID)listID
                      listKind:(NTYTListKind)listKind
                    targetKind:(NTYTTargetKind)targetKind
        applicableContentTypes:(NSSet<NSNumber *> *)applicableContentTypes
                   storagePath:(NSArray<NSString *> *)storagePath
              supportedOptionIDs:(NSSet<NSNumber *> *)supportedOptionIDs
                defaultMatchOptionState:(NTYTMatchOptionState *)defaultMatchOptionState;

@end

@implementation NTYTListDefinition

- (instancetype)initWithListID:(NTYTListID)listID
                      listKind:(NTYTListKind)listKind
                    targetKind:(NTYTTargetKind)targetKind
        applicableContentTypes:(NSSet<NSNumber *> *)applicableContentTypes
                   storagePath:(NSArray<NSString *> *)storagePath
              supportedOptionIDs:(NSSet<NSNumber *> *)supportedOptionIDs
                defaultMatchOptionState:(NTYTMatchOptionState *)defaultMatchOptionState {
    self = [super init];
    if (self) {
        _listID = listID;
        _listKind = listKind;
        _targetKind = targetKind;
        _applicableContentTypes = [applicableContentTypes copy];
        _storagePath = [storagePath copy];
        _supportedOptionIDs = [supportedOptionIDs copy];
        _defaultMatchOptionState = defaultMatchOptionState;
    }
    return self;
}

- (BOOL)appliesToContentType:(NTYTContentType)contentType {
    return [self.applicableContentTypes containsObject:@(contentType)];
}

- (BOOL)supportsOption:(NTYTListOptionID)optionID {
    return [self.supportedOptionIDs containsObject:@(optionID)];
}

- (BOOL)defaultValueForOption:(NTYTListOptionID)optionID {
    switch (optionID) {
        case NTYTListOptionIDCaseSensitive:
            return self.defaultMatchOptionState.caseSensitive;
        case NTYTListOptionIDExactMatch:
            return self.defaultMatchOptionState.exactMatch;
    }
    return NO;
}

+ (NSArray<NTYTListDefinition *> *)allDefinitions {
    static NSArray<NTYTListDefinition *> *definitions;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSSet<NSNumber *> *plainOptionIDs = [NSSet setWithArray:@[
            @(NTYTListOptionIDCaseSensitive),
            @(NTYTListOptionIDExactMatch),
        ]];
        NSSet<NSNumber *> *noOptionIDs = [NSSet set];
        NSSet<NSNumber *> *allContentTypes = [NSSet setWithArray:@[
            @(NTYTContentTypeVideo),
            @(NTYTContentTypePost),
            @(NTYTContentTypePlaylistNormal),
            @(NTYTContentTypePlaylistMix),
        ]];
        NSSet<NSNumber *> *videoContentTypes = [NSSet setWithObject:@(NTYTContentTypeVideo)];
        NSSet<NSNumber *> *postContentTypes = [NSSet setWithObject:@(NTYTContentTypePost)];
        NSSet<NSNumber *> *playlistContentTypes = [NSSet setWithArray:@[
            @(NTYTContentTypePlaylistNormal),
            @(NTYTContentTypePlaylistMix),
        ]];

        NTYTMatchOptionState *offOff =
            [[NTYTMatchOptionState alloc] initWithCaseSensitive:NO exactMatch:NO];
        NTYTMatchOptionState *offOn =
            [[NTYTMatchOptionState alloc] initWithCaseSensitive:NO exactMatch:YES];
        NTYTMatchOptionState *onOn =
            [[NTYTMatchOptionState alloc] initWithCaseSensitive:YES exactMatch:YES];

        definitions = @[
            [[self alloc] initWithListID:NTYTListIDGeneralBlock
                                listKind:NTYTListKindBlock
                              targetKind:NTYTTargetKindGeneral
                  applicableContentTypes:allContentTypes
                             storagePath:@[@"general", @"block"]
                        supportedOptionIDs:plainOptionIDs
                          defaultMatchOptionState:offOff],
            [[self alloc] initWithListID:NTYTListIDGeneralAllow
                                listKind:NTYTListKindAllow
                              targetKind:NTYTTargetKindGeneral
                  applicableContentTypes:allContentTypes
                             storagePath:@[@"general", @"allow"]
                        supportedOptionIDs:plainOptionIDs
                          defaultMatchOptionState:offOff],
            [[self alloc] initWithListID:NTYTListIDVideoTitle
                                listKind:NTYTListKindBlock
                              targetKind:NTYTTargetKindTitle
                  applicableContentTypes:videoContentTypes
                             storagePath:@[@"video", @"title"]
                        supportedOptionIDs:plainOptionIDs
                          defaultMatchOptionState:offOff],
            [[self alloc] initWithListID:NTYTListIDVideoChannel
                                listKind:NTYTListKindBlock
                              targetKind:NTYTTargetKindChannel
                  applicableContentTypes:videoContentTypes
                             storagePath:@[@"video", @"channel"]
                        supportedOptionIDs:plainOptionIDs
                          defaultMatchOptionState:offOn],
            [[self alloc] initWithListID:NTYTListIDVideoID
                                listKind:NTYTListKindBlock
                              targetKind:NTYTTargetKindVideoID
                  applicableContentTypes:videoContentTypes
                             storagePath:@[@"video", @"id"]
                        supportedOptionIDs:noOptionIDs
                          defaultMatchOptionState:onOn],
            [[self alloc] initWithListID:NTYTListIDChannelBlock
                                listKind:NTYTListKindBlock
                              targetKind:NTYTTargetKindChannel
                  applicableContentTypes:allContentTypes
                             storagePath:@[@"channel", @"block"]
                        supportedOptionIDs:plainOptionIDs
                          defaultMatchOptionState:offOn],
            [[self alloc] initWithListID:NTYTListIDChannelAllow
                                listKind:NTYTListKindAllow
                              targetKind:NTYTTargetKindChannel
                  applicableContentTypes:allContentTypes
                             storagePath:@[@"channel", @"allow"]
                        supportedOptionIDs:plainOptionIDs
                          defaultMatchOptionState:offOn],
            [[self alloc] initWithListID:NTYTListIDPostContent
                                listKind:NTYTListKindBlock
                              targetKind:NTYTTargetKindPostBody
                  applicableContentTypes:postContentTypes
                             storagePath:@[@"post", @"content"]
                        supportedOptionIDs:plainOptionIDs
                          defaultMatchOptionState:offOff],
            [[self alloc] initWithListID:NTYTListIDPostChannel
                                listKind:NTYTListKindBlock
                              targetKind:NTYTTargetKindChannel
                  applicableContentTypes:postContentTypes
                             storagePath:@[@"post", @"channel"]
                        supportedOptionIDs:plainOptionIDs
                          defaultMatchOptionState:offOn],
            [[self alloc] initWithListID:NTYTListIDPostID
                                listKind:NTYTListKindBlock
                              targetKind:NTYTTargetKindPostID
                  applicableContentTypes:postContentTypes
                             storagePath:@[@"post", @"id"]
                        supportedOptionIDs:noOptionIDs
                          defaultMatchOptionState:onOn],
            [[self alloc] initWithListID:NTYTListIDPlaylistTitle
                                listKind:NTYTListKindBlock
                              targetKind:NTYTTargetKindTitle
                  applicableContentTypes:playlistContentTypes
                             storagePath:@[@"playlist", @"title"]
                        supportedOptionIDs:plainOptionIDs
                          defaultMatchOptionState:offOff],
            [[self alloc] initWithListID:NTYTListIDPlaylistChannel
                                listKind:NTYTListKindBlock
                              targetKind:NTYTTargetKindChannel
                  applicableContentTypes:playlistContentTypes
                             storagePath:@[@"playlist", @"channel"]
                        supportedOptionIDs:plainOptionIDs
                          defaultMatchOptionState:offOn],
            [[self alloc] initWithListID:NTYTListIDPlaylistID
                                listKind:NTYTListKindBlock
                              targetKind:NTYTTargetKindPlaylistID
                  applicableContentTypes:playlistContentTypes
                             storagePath:@[@"playlist", @"id"]
                        supportedOptionIDs:noOptionIDs
                          defaultMatchOptionState:onOn],
            [[self alloc] initWithListID:NTYTListIDGlobalBlock
                                listKind:NTYTListKindBlock
                              targetKind:NTYTTargetKindGlobal
                  applicableContentTypes:allContentTypes
                             storagePath:@[@"global", @"block"]
                        supportedOptionIDs:plainOptionIDs
                          defaultMatchOptionState:offOff],
            [[self alloc] initWithListID:NTYTListIDGlobalAllow
                                listKind:NTYTListKindAllow
                              targetKind:NTYTTargetKindGlobal
                  applicableContentTypes:allContentTypes
                             storagePath:@[@"global", @"allow"]
                        supportedOptionIDs:plainOptionIDs
                          defaultMatchOptionState:offOff],
        ];
    });
    return definitions;
}

+ (NTYTListDefinition *)definitionForListID:(NTYTListID)listID {
    for (NTYTListDefinition *definition in self.allDefinitions) {
        if (definition.listID == listID) {
            return definition;
        }
    }
    return nil;
}

@end
