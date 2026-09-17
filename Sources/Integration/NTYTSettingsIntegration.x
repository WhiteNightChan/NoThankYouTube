#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/message.h>
#import <objc/runtime.h>

#import "Debug/LogHelper.h"
#import "UI/NTYTCategoryViewController.h"
#import "UI/NTYTUIStrings.h"

static const NSInteger NTYTSettingsCategory = 'ntyt';

@interface YTSettingsGroupData : NSObject
@property(nonatomic, readonly) NSUInteger type;
+ (NSMutableArray<NSNumber *> *)tweaks;
- (NSArray<NSNumber *> *)orderedCategories;
@end

@interface YTSettingsSectionItem : NSObject
+ (instancetype)itemWithTitle:(NSString *)title
             titleDescription:(nullable NSString *)titleDescription
       accessibilityIdentifier:(nullable NSString *)accessibilityIdentifier
               detailTextBlock:(nullable id)detailTextBlock
                   selectBlock:(BOOL (^)(id cell, NSUInteger argument))selectBlock;
@end

@interface NSObject (NTYTSettingsSectionInstalling)
- (void)setSectionItems:(NSArray *)items
            forCategory:(NSInteger)category
                  title:(NSString *)title
                   icon:(nullable UIImage *)icon
       titleDescription:(nullable NSString *)titleDescription
           headerHidden:(BOOL)headerHidden;
- (void)setSectionItems:(NSArray *)items
            forCategory:(NSInteger)category
                  title:(NSString *)title
       titleDescription:(nullable NSString *)titleDescription
           headerHidden:(BOOL)headerHidden;
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
    Class groupDataClass = NSClassFromString(@"YTSettingsGroupData");
    return groupDataClass &&
        class_getClassMethod(groupDataClass, @selector(tweaks)) != NULL;
}

static void NTYTRegisterWithYouGroupSettingsIfAvailable(void) {
    Class groupDataClass = NSClassFromString(@"YTSettingsGroupData");
    SEL selector = @selector(tweaks);

    if (!groupDataClass ||
        class_getClassMethod(groupDataClass, selector) == NULL) {
        return;
    }

    typedef id (*TweaksGetter)(id, SEL);
    id value = ((TweaksGetter)objc_msgSend)(groupDataClass, selector);
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

static id NTYTSectionItemForPage(NTYTSettingsCategoryPage page) {
    Class itemClass = NSClassFromString(@"YTSettingsSectionItem");
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
    BOOL (^selectBlock)(id, NSUInteger) = ^BOOL(id cell, __unused NSUInteger argument) {
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

    typedef id (*ItemFactory)(id, SEL, id, id, id, id, id);
    id item = ((ItemFactory)objc_msgSend)(itemClass,
                                         selector,
                                         title,
                                         nil,
                                         [NSString stringWithFormat:@"ntyt.%lu", (unsigned long)page],
                                         nil,
                                         [selectBlock copy]);

    NTYTLog(@"[SettingsIntegration] item factory page=%lu result=%@",
            (unsigned long)page,
            item ? @"success" : @"nil");

    return item;
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
    id general = NTYTSectionItemForPage(NTYTSettingsCategoryPageGeneral);
    id videos = NTYTSectionItemForPage(NTYTSettingsCategoryPageVideos);
    id channels = NTYTSectionItemForPage(NTYTSettingsCategoryPageChannels);

    if (!general || !videos || !channels) {
        NTYTLog(@"[SettingsIntegration] install failed: section items general=%@ videos=%@ channels=%@",
                general ? @"OK" : @"nil",
                videos ? @"OK" : @"nil",
                channels ? @"OK" : @"nil");
        return NO;
    }

    id controller = NTYTSettingsViewControllerCandidate(manager, entry);
    if (!controller) {
        NTYTLog(@"[SettingsIntegration] install failed: settings controller not found");
        return NO;
    }

    NSArray *items = @[general, videos, channels];

    SEL modern = @selector(setSectionItems:forCategory:title:icon:titleDescription:headerHidden:);
    if ([controller respondsToSelector:modern]) {
        NTYTLog(@"[SettingsIntegration] install using modern setter controller=%@",
                NSStringFromClass([controller class]));

        typedef void (*ModernSetter)(id, SEL, id, NSInteger, id, id, id, BOOL);
        ((ModernSetter)objc_msgSend)(controller,
                                    modern,
                                    items,
                                    NTYTSettingsCategory,
                                    @"NoThankYouTube",
                                    nil,
                                    nil,
                                    NO);
        return YES;
    }

    SEL legacy = @selector(setSectionItems:forCategory:title:titleDescription:headerHidden:);
    if ([controller respondsToSelector:legacy]) {
        NTYTLog(@"[SettingsIntegration] install using legacy setter controller=%@",
                NSStringFromClass([controller class]));

        typedef void (*LegacySetter)(id, SEL, id, NSInteger, id, id, BOOL);
        ((LegacySetter)objc_msgSend)(controller,
                                    legacy,
                                    items,
                                    NTYTSettingsCategory,
                                    @"NoThankYouTube",
                                    nil,
                                    NO);
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

- (void)updateSectionForCategory:(NSInteger)category withEntry:(id)entry {
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

+ (NSArray *)orderedGroups {
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
