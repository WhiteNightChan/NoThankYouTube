#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <YouTubeHeader/YTIIcon.h>
#import <YouTubeHeader/YTAppSettingsGroupPresentationData.h>
#import <YouTubeHeader/YTAppSettingsPresentationData.h>
#import <YouTubeHeader/YTSettingsCell.h>
#import <YouTubeHeader/YTSettingsGroupData.h>
#import <YouTubeHeader/YTSettingsSectionItem.h>
#import <YouTubeHeader/YTSettingsSectionItemManager.h>
#import <YouTubeHeader/YTSettingsViewController.h>

#import "Debug/LogHelper.h"
#import "UI/NTYTCategoryViewController.h"
#import "Localization/NTYTUIStrings.h"
#import "UI/NTYTSettingsTransferFlowController.h"

static const NSInteger NTYTSettingsCategory = 'ntyt';

@interface YTSettingsGroupData (NTYTYouGroupSettings)
+ (NSMutableArray<NSNumber *> *)tweaks;
@end

static NSArray<NSNumber *> *NTYTArrayByAddingCategoryOnce(NSArray<NSNumber *> *original) {
    if (![original isKindOfClass:[NSArray class]]) {
        return original;
    }
    NSNumber *category = @(NTYTSettingsCategory);
    if ([original containsObject:category]) {
        return original;
    }
    NSMutableArray<NSNumber *> *result = [original mutableCopy];
    [result addObject:category];
    return result;
}

static BOOL NTYTYouGroupSettingsIsPresent(void) {
    Class groupDataClass = %c(YTSettingsGroupData);
    return groupDataClass &&
        [groupDataClass respondsToSelector:@selector(tweaks)];
}

static void NTYTRegisterWithYouGroupSettingsIfAvailable(void) {
    Class groupDataClass = %c(YTSettingsGroupData);

    if (!groupDataClass ||
        ![groupDataClass respondsToSelector:@selector(tweaks)]) {
        return;
    }

    id value = [groupDataClass tweaks];
    if (![value isKindOfClass:[NSMutableArray class]]) {
        return;
    }

    NSMutableArray<NSNumber *> *tweaks = value;
    NSNumber *category = @(NTYTSettingsCategory);
    if (![tweaks containsObject:category]) {
        [tweaks addObject:category];
    }
}

static UIViewController *NTYTViewControllerFromResponder(id object) {
    UIResponder *responder = [object isKindOfClass:[UIResponder class]] ? object : nil;
    while (responder) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
        responder = responder.nextResponder;
    }
    return nil;
}

static YTSettingsSectionItem *NTYTSectionItemForPage(NTYTSettingsCategoryPage page) {
    Class itemClass = %c(YTSettingsSectionItem);
    SEL selector = @selector(itemWithTitle:titleDescription:accessibilityIdentifier:detailTextBlock:selectBlock:);

    BOOL selectorAvailable =
        itemClass && [itemClass respondsToSelector:selector];

    NTYTLog(@"[SettingsIntegration] item factory page=%lu class=%@ selectorAvailable=%@",
            (unsigned long)page,
            itemClass ? NSStringFromClass(itemClass) : @"<nil>",
            selectorAvailable ? @"YES" : @"NO");

    if (!selectorAvailable) {
        return nil;
    }

    NSString *title = NTYTCategoryTitle(page);
    BOOL (^selectBlock)(YTSettingsCell *, NSUInteger) =
        ^BOOL(YTSettingsCell *cell, __unused NSUInteger argument) {
        UIViewController *source = NTYTViewControllerFromResponder(cell);
        UINavigationController *navigationController = source.navigationController;
        if (!navigationController) {
            return NO;
        }
        NTYTCategoryViewController *controller =
            [[NTYTCategoryViewController alloc] initWithCategoryPage:page];
        [navigationController pushViewController:controller animated:YES];
        return YES;
    };

    YTSettingsSectionItem *item =
        [itemClass itemWithTitle:title
               titleDescription:nil
         accessibilityIdentifier:[NSString stringWithFormat:@"ntyt.%lu", (unsigned long)page]
                 detailTextBlock:nil
                     selectBlock:[selectBlock copy]];

    NTYTLog(@"[SettingsIntegration] item factory page=%lu result=%@",
            (unsigned long)page,
            item ? @"success" : @"nil");

    return item;
}

static YTSettingsSectionItem *NTYTSectionItemForTransferAction(BOOL importAction) {
    Class itemClass = %c(YTSettingsSectionItem);
    SEL selector = @selector(itemWithTitle:titleDescription:accessibilityIdentifier:detailTextBlock:selectBlock:);
    if (!itemClass || ![itemClass respondsToSelector:selector]) {
        return nil;
    }

    BOOL (^selectBlock)(YTSettingsCell *, NSUInteger) =
        ^BOOL(YTSettingsCell *cell, __unused NSUInteger argument) {
        UIViewController *source = NTYTViewControllerFromResponder(cell);
        if (!source) {
            return NO;
        }
        if (importAction) {
            [NTYTSettingsTransferFlowController startImportFromViewController:source];
        } else {
            [NTYTSettingsTransferFlowController startExportFromViewController:source];
        }
        return YES;
    };

    return [itemClass itemWithTitle:importAction ? NTYTImportSettingsTitle() : NTYTExportSettingsTitle()
                  titleDescription:nil
            accessibilityIdentifier:importAction ? @"ntyt.import" : @"ntyt.export"
                    detailTextBlock:nil
                        selectBlock:[selectBlock copy]];
}

static YTSettingsSectionItem *NTYTSectionItemForVersion(void) {
    Class itemClass = %c(YTSettingsSectionItem);
    SEL selector = @selector(itemWithTitle:titleDescription:accessibilityIdentifier:detailTextBlock:selectBlock:);
    if (!itemClass || ![itemClass respondsToSelector:selector]) {
        return nil;
    }

    return [itemClass itemWithTitle:NTYTTweakVersionTitle()
                  titleDescription:nil
            accessibilityIdentifier:@"ntyt.version"
                    detailTextBlock:^NSString *{
                        return NTYT_PACKAGE_VERSION;
                    }
                        selectBlock:nil];
}

static id NTYTObjectForKeySafely(id object, NSString *key) {
    if (!object || key.length == 0) {
        return nil;
    }
    @try {
        return [object valueForKey:key];
    } @catch (__unused NSException *exception) {
        return nil;
    }
}

static id NTYTSettingsViewControllerCandidate(id manager, id entry) {
    SEL modern = @selector(setSectionItems:forCategory:title:icon:titleDescription:headerHidden:);
    SEL legacy = @selector(setSectionItems:forCategory:title:titleDescription:headerHidden:);
    NSArray *directCandidates = @[
        NTYTObjectForKeySafely(manager, @"_dataDelegate") ?: [NSNull null],
        entry ?: [NSNull null],
        manager ?: [NSNull null],
        NTYTObjectForKeySafely(manager, @"settingsViewController") ?: [NSNull null],
        NTYTObjectForKeySafely(manager, @"_settingsViewController") ?: [NSNull null],
        NTYTObjectForKeySafely(entry, @"settingsViewController") ?: [NSNull null],
    ];

    NTYTLog(@"[SettingsIntegration] controller search manager=%@ entry=%@",
            manager ? NSStringFromClass([manager class]) : @"<nil>",
            entry ? NSStringFromClass([entry class]) : @"<nil>");

    for (id candidate in directCandidates) {
        if (candidate == [NSNull null]) {
            NTYTLog(@"[SettingsIntegration] controller candidate=<nil>");
            continue;
        }

        BOOL hasModern = [candidate respondsToSelector:modern];
        BOOL hasLegacy = [candidate respondsToSelector:legacy];

        NTYTLog(@"[SettingsIntegration] controller candidate=%@ modern=%@ legacy=%@",
                NSStringFromClass([candidate class]),
                hasModern ? @"YES" : @"NO",
                hasLegacy ? @"YES" : @"NO");

        if (hasModern || hasLegacy) {
            return candidate;
        }
    }

    return nil;
}

static BOOL NTYTInstallSettingsSection(id manager, id entry) {
    YTSettingsSectionItem *general =
        NTYTSectionItemForPage(NTYTSettingsCategoryPageGeneral);
    YTSettingsSectionItem *videoItem =
        NTYTSectionItemForPage(NTYTSettingsCategoryPageVideo);
    YTSettingsSectionItem *channelItem =
        NTYTSectionItemForPage(NTYTSettingsCategoryPageChannel);
    YTSettingsSectionItem *postItem =
        NTYTSectionItemForPage(NTYTSettingsCategoryPagePost);
    YTSettingsSectionItem *playlistItem =
        NTYTSectionItemForPage(NTYTSettingsCategoryPagePlaylist);
    YTSettingsSectionItem *global =
        NTYTSectionItemForPage(NTYTSettingsCategoryPageGlobal);
    YTSettingsSectionItem *optionItem =
        NTYTSectionItemForPage(NTYTSettingsCategoryPageOption);
    YTSettingsSectionItem *importSettings =
        NTYTSectionItemForTransferAction(YES);
    YTSettingsSectionItem *exportSettings =
        NTYTSectionItemForTransferAction(NO);
    YTSettingsSectionItem *versionItem =
        NTYTSectionItemForVersion();

    if (!general || !videoItem || !channelItem || !postItem || !playlistItem || !global || !optionItem ||
        !importSettings || !exportSettings || !versionItem) {
        NTYTLog(@"[SettingsIntegration] install failed: section items general=%@ videos=%@ channels=%@ posts=%@ playlists=%@ global=%@",
                general ? @"OK" : @"nil",
                videoItem ? @"OK" : @"nil",
                channelItem ? @"OK" : @"nil",
                postItem ? @"OK" : @"nil",
                playlistItem ? @"OK" : @"nil",
                global ? @"OK" : @"nil");
        return NO;
    }

    id controller = NTYTSettingsViewControllerCandidate(manager, entry);
    if (!controller) {
        NTYTLog(@"[SettingsIntegration] install failed: settings controller not found");
        return NO;
    }

    NSMutableArray<YTSettingsSectionItem *> *items =
        [@[global, channelItem, general, videoItem, postItem, playlistItem, optionItem,
           importSettings, exportSettings, versionItem] mutableCopy];

    SEL modern = @selector(setSectionItems:forCategory:title:icon:titleDescription:headerHidden:);
    if ([controller respondsToSelector:modern]) {
        NTYTLog(@"[SettingsIntegration] install using modern setter controller=%@",
                NSStringFromClass([controller class]));

        Class iconClass = %c(YTIIcon);
        YTIIcon *icon = [iconClass new];
        icon.iconType = (YTIcon)433; // YTIcons: NOT_INTERESTED

        [controller setSectionItems:items
                       forCategory:NTYTSettingsCategory
                             title:NTYTAppName()
                              icon:icon
                  titleDescription:nil
                      headerHidden:NO];
        return YES;
    }

    SEL legacy = @selector(setSectionItems:forCategory:title:titleDescription:headerHidden:);
    if ([controller respondsToSelector:legacy]) {
        NTYTLog(@"[SettingsIntegration] install using legacy setter controller=%@",
                NSStringFromClass([controller class]));

        [controller setSectionItems:items
                       forCategory:NTYTSettingsCategory
                             title:NTYTAppName()
                  titleDescription:nil
                      headerHidden:NO];
        return YES;
    }

    NTYTLog(@"[SettingsIntegration] install failed: controller=%@ has no supported setter",
            NSStringFromClass([controller class]));

    return NO;
}

%group NTYTNormalSettings

%hook YTAppSettingsPresentationData

+ (NSArray<NSNumber *> *)settingsCategoryOrder {
    return NTYTArrayByAddingCategoryOnce(%orig);
}

%end

%hook YTSettingsSectionItemManager

- (void)updateSectionForCategory:(NSUInteger)category
                       withEntry:(id)entry {
    if (category == NTYTSettingsCategory) {
        BOOL installed = NTYTInstallSettingsSection(self, entry);

        NTYTLog(@"[SettingsIntegration] NTYT section install=%@",
                installed ? @"success" : @"failed");

        if (!installed) {
            %orig;
        }
        return;
    }
    %orig;
}

%end

%end


%group NTYTGroupedPresenceBridge

%hook YTAppSettingsGroupPresentationData

+ (NSArray<YTSettingsGroupData *> *)orderedGroups {
    NTYTRegisterWithYouGroupSettingsIfAvailable();
    return %orig;
}

%end

%end


%group NTYTYouGroupSettingsPresent

%hook YTSettingsGroupData

+ (NSMutableArray<NSNumber *> *)tweaks {
    NSMutableArray<NSNumber *> *tweaks = %orig;
    if (![tweaks isKindOfClass:[NSMutableArray class]]) {
        return tweaks;
    }

    NSNumber *category = @(NTYTSettingsCategory);
    if (![tweaks containsObject:category]) {
        [tweaks addObject:category];
    }

    return tweaks;
}

%end

%end


%group NTYTStandaloneGroupedFallback

%hook YTSettingsGroupData

- (NSArray<NSNumber *> *)orderedCategories {
    NSArray<NSNumber *> *original = %orig;

    if (NTYTYouGroupSettingsIsPresent()) {
        NTYTRegisterWithYouGroupSettingsIfAvailable();
        return original;
    }

    if (self.type != 1) {
        return original;
    }

    return NTYTArrayByAddingCategoryOnce(original);
}

%end

%end


%ctor {
    @autoreleasepool {
        BOOL youGroupSettingsPresent = NTYTYouGroupSettingsIsPresent();

        NTYTLog(@"[SettingsIntegration] ctor YouGroupSettings=%@",
                youGroupSettingsPresent ? @"present" : @"absent");

        %init(NTYTNormalSettings);
        %init(NTYTGroupedPresenceBridge);
        %init(NTYTStandaloneGroupedFallback);

        if (youGroupSettingsPresent) {
            %init(NTYTYouGroupSettingsPresent);
        }
    }
}
