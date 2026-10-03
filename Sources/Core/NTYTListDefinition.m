#import "NTYTListDefinition.h"

@implementation NTYTMatchOptions

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
              supportedOptions:(NSSet<NSNumber *> *)supportedOptions
                defaultOptions:(NTYTMatchOptions *)defaultOptions;

@end

@implementation NTYTListDefinition

- (instancetype)initWithListID:(NTYTListID)listID
                      listKind:(NTYTListKind)listKind
                    targetKind:(NTYTTargetKind)targetKind
        applicableContentTypes:(NSSet<NSNumber *> *)applicableContentTypes
                   storagePath:(NSArray<NSString *> *)storagePath
              supportedOptions:(NSSet<NSNumber *> *)supportedOptions
                defaultOptions:(NTYTMatchOptions *)defaultOptions {
    self = [super init];
    if (self) {
        _listID = listID;
        _listKind = listKind;
        _targetKind = targetKind;
        _applicableContentTypes = [applicableContentTypes copy];
        _storagePath = [storagePath copy];
        _supportedOptions = [supportedOptions copy];
        _defaultOptions = defaultOptions;
    }
    return self;
}

- (BOOL)appliesToContentType:(NTYTContentType)contentType {
    return [self.applicableContentTypes containsObject:@(contentType)];
}

- (BOOL)supportsOption:(NTYTListOptionID)optionID {
    return [self.supportedOptions containsObject:@(optionID)];
}

- (BOOL)defaultValueForOption:(NTYTListOptionID)optionID {
    switch (optionID) {
        case NTYTListOptionIDCaseSensitive:
            return self.defaultOptions.caseSensitive;
        case NTYTListOptionIDExactMatch:
            return self.defaultOptions.exactMatch;
    }
    return NO;
}

+ (NSArray<NTYTListDefinition *> *)allDefinitions {
    static NSArray<NTYTListDefinition *> *definitions;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSSet<NSNumber *> *plainOptions = [NSSet setWithArray:@[
            @(NTYTListOptionIDCaseSensitive),
            @(NTYTListOptionIDExactMatch),
        ]];
        NSSet<NSNumber *> *noOptions = [NSSet set];
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

        NTYTMatchOptions *offOff =
            [[NTYTMatchOptions alloc] initWithCaseSensitive:NO exactMatch:NO];
        NTYTMatchOptions *offOn =
            [[NTYTMatchOptions alloc] initWithCaseSensitive:NO exactMatch:YES];
        NTYTMatchOptions *onOn =
            [[NTYTMatchOptions alloc] initWithCaseSensitive:YES exactMatch:YES];

        definitions = @[
            [[self alloc] initWithListID:NTYTListIDGeneralBlock
                                listKind:NTYTListKindBlock
                              targetKind:NTYTTargetKindGeneral
                  applicableContentTypes:allContentTypes
                             storagePath:@[@"general", @"block"]
                        supportedOptions:plainOptions
                          defaultOptions:offOff],
            [[self alloc] initWithListID:NTYTListIDGeneralAllow
                                listKind:NTYTListKindAllow
                              targetKind:NTYTTargetKindGeneral
                  applicableContentTypes:allContentTypes
                             storagePath:@[@"general", @"allow"]
                        supportedOptions:plainOptions
                          defaultOptions:offOff],
            [[self alloc] initWithListID:NTYTListIDVideosTitle
                                listKind:NTYTListKindBlock
                              targetKind:NTYTTargetKindTitle
                  applicableContentTypes:videoContentTypes
                             storagePath:@[@"videos", @"title"]
                        supportedOptions:plainOptions
                          defaultOptions:offOff],
            [[self alloc] initWithListID:NTYTListIDVideosChannel
                                listKind:NTYTListKindBlock
                              targetKind:NTYTTargetKindChannel
                  applicableContentTypes:videoContentTypes
                             storagePath:@[@"videos", @"channel"]
                        supportedOptions:plainOptions
                          defaultOptions:offOn],
            [[self alloc] initWithListID:NTYTListIDVideosID
                                listKind:NTYTListKindBlock
                              targetKind:NTYTTargetKindVideoID
                  applicableContentTypes:videoContentTypes
                             storagePath:@[@"videos", @"id"]
                        supportedOptions:noOptions
                          defaultOptions:onOn],
            [[self alloc] initWithListID:NTYTListIDChannelsBlock
                                listKind:NTYTListKindBlock
                              targetKind:NTYTTargetKindChannel
                  applicableContentTypes:allContentTypes
                             storagePath:@[@"channels", @"block"]
                        supportedOptions:plainOptions
                          defaultOptions:offOn],
            [[self alloc] initWithListID:NTYTListIDChannelsAllow
                                listKind:NTYTListKindAllow
                              targetKind:NTYTTargetKindChannel
                  applicableContentTypes:allContentTypes
                             storagePath:@[@"channels", @"allow"]
                        supportedOptions:plainOptions
                          defaultOptions:offOn],
            [[self alloc] initWithListID:NTYTListIDPostContent
                                listKind:NTYTListKindBlock
                              targetKind:NTYTTargetKindPostBody
                  applicableContentTypes:postContentTypes
                             storagePath:@[@"posts", @"content"]
                        supportedOptions:plainOptions
                          defaultOptions:offOff],
            [[self alloc] initWithListID:NTYTListIDPostChannel
                                listKind:NTYTListKindBlock
                              targetKind:NTYTTargetKindChannel
                  applicableContentTypes:postContentTypes
                             storagePath:@[@"posts", @"channel"]
                        supportedOptions:plainOptions
                          defaultOptions:offOn],
            [[self alloc] initWithListID:NTYTListIDPlaylistTitle
                                listKind:NTYTListKindBlock
                              targetKind:NTYTTargetKindTitle
                  applicableContentTypes:playlistContentTypes
                             storagePath:@[@"playlists", @"title"]
                        supportedOptions:plainOptions
                          defaultOptions:offOff],
            [[self alloc] initWithListID:NTYTListIDPlaylistChannel
                                listKind:NTYTListKindBlock
                              targetKind:NTYTTargetKindChannel
                  applicableContentTypes:playlistContentTypes
                             storagePath:@[@"playlists", @"channel"]
                        supportedOptions:plainOptions
                          defaultOptions:offOn],
            [[self alloc] initWithListID:NTYTListIDPlaylistID
                                listKind:NTYTListKindBlock
                              targetKind:NTYTTargetKindPlaylistID
                  applicableContentTypes:playlistContentTypes
                             storagePath:@[@"playlists", @"id"]
                        supportedOptions:noOptions
                          defaultOptions:onOn],
            [[self alloc] initWithListID:NTYTListIDGlobalBlock
                                listKind:NTYTListKindBlock
                              targetKind:NTYTTargetKindGlobal
                  applicableContentTypes:allContentTypes
                             storagePath:@[@"global", @"block"]
                        supportedOptions:plainOptions
                          defaultOptions:offOff],
            [[self alloc] initWithListID:NTYTListIDGlobalAllow
                                listKind:NTYTListKindAllow
                              targetKind:NTYTTargetKindGlobal
                  applicableContentTypes:allContentTypes
                             storagePath:@[@"global", @"allow"]
                        supportedOptions:plainOptions
                          defaultOptions:offOff],
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
