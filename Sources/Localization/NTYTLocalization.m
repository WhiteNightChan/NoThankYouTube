#import "NTYTLocalization.h"

#import <rootless.h>

NSString *NTYTLocalizedString(NSString *key) {
    NSString *bundlePath = ROOT_PATH_NS(@"/Library/Application Support/NoThankYouTube.bundle");
    NSBundle *resources = [NSBundle bundleWithPath:bundlePath];
    if (!resources) {
        return key;
    }

    NSString *effective = [NSBundle mainBundle].preferredLocalizations.firstObject;
    NSDictionary *components = [NSLocale componentsFromLocaleIdentifier:effective ?: @""];
    NSString *language = components[NSLocaleLanguageCode];
    NSString *selected = [language isEqualToString:@"ja"] ? @"ja" : @"en";
    NSString *missing = [NSUUID UUID].UUIDString;

    NSString *selectedPath = [resources pathForResource:selected ofType:@"lproj"];
    NSBundle *selectedBundle = selectedPath ? [NSBundle bundleWithPath:selectedPath] : nil;
    if (selectedBundle) {
        NSString *value = [selectedBundle localizedStringForKey:key value:missing table:@"Localizable"];
        if (![value isEqualToString:missing]) {
            return value;
        }
    }

    if (![selected isEqualToString:@"en"]) {
        NSString *englishPath = [resources pathForResource:@"en" ofType:@"lproj"];
        NSBundle *englishBundle = englishPath ? [NSBundle bundleWithPath:englishPath] : nil;
        if (englishBundle) {
            NSString *value = [englishBundle localizedStringForKey:key value:missing table:@"Localizable"];
            if (![value isEqualToString:missing]) {
                return value;
            }
        }
    }
    return key;
}
