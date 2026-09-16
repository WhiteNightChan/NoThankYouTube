#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/message.h>
#import <objc/runtime.h>

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
    if (!itemClass || ![itemClass respondsToSelector:selector]) {
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
    return ((ItemFactory)objc_msgSend)(itemClass,
                                      selector,
                                      title,
                                      nil,
                                      [NSString stringWithFormat:@"ntyt.%lu", (unsigned long)page],
                                      nil,
                                      [selectBlock copy]);
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
        entry ?: [NSNull null],
        manager ?: [NSNull null],
        NTYTObjectForKeySafely(manager, @"settingsViewController") ?: [NSNull null],
        NTYTObjectForKeySafely(manager, @"_settingsViewController") ?: [NSNull null],
        NTYTObjectForKeySafely(entry, @"settingsViewController") ?: [NSNull null],
    ];
    for (id candidate in directCandidates) {
        if (candidate != [NSNull null] &&
            ([candidate respondsToSelector:modern] || [candidate respondsToSelector:legacy])) {
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
        return NO;
    }

    id controller = NTYTSettingsViewControllerCandidate(manager, entry);
    if (!controller) {
        return NO;
    }
    NSArray *items = @[general, videos, channels];

    SEL modern = @selector(setSectionItems:forCategory:title:icon:titleDescription:headerHidden:);
    if ([controller respondsToSelector:modern]) {
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
        if (!NTYTInstallSettingsSection(self, entry)) {
            %orig;
        }
        return;
    }
    %orig;
}

%end

%end


%group NTYTYouGroupSettingsPresent

%hook YTSettingsGroupData

+ (NSMutableArray<NSNumber *> *)tweaks {
    NSArray<NSNumber *> *original = %orig;
    NSArray<NSNumber *> *registered = NTYTArrayByAddingCategoryOnce(original);
    return [registered mutableCopy];
}

%end

%end


%group NTYTStandaloneGroupedFallback

%hook YTSettingsGroupData

- (NSArray<NSNumber *> *)orderedCategories {
    NSArray<NSNumber *> *original = %orig;
    if (self.type != 1) {
        return original;
    }
    return NTYTArrayByAddingCategoryOnce(original);
}

%end

%end


%ctor {
    @autoreleasepool {
        %init(NTYTNormalSettings);

        Class groupDataClass = NSClassFromString(@"YTSettingsGroupData");
        BOOL youGroupSettingsPresent = groupDataClass &&
            class_getClassMethod(groupDataClass, @selector(tweaks)) != NULL;
        if (youGroupSettingsPresent) {
            %init(NTYTYouGroupSettingsPresent);
        } else {
            %init(NTYTStandaloneGroupedFallback);
        }
    }
}
