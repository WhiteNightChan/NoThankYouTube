#import <Foundation/Foundation.h>

#import <YouTubeHeader/YTInnerTubeCollectionViewController.h>

#import "NTYTProductionFilter.h"
#import "Persistence/NTYTSettingsCoordinator.h"
#import "Debug/LogHelper.h"

%hook YTInnerTubeCollectionViewController

- (void)displaySectionsWithReloadingSectionControllerByRenderer:(id)renderer {
    @try {
        id originalValue = [self valueForKey:@"_sectionRenderers"];
        if ([originalValue isKindOfClass:[NSArray class]]) {
            NSArray *original = (NSArray *)originalValue;
            NSArray *filtered =
                [NTYTProductionFilter filteredSectionCollectionFromOriginal:original];
            NTYTLog(@"[Hook] displaySections: input=%lu output=%lu changed=%@",
                    (unsigned long)original.count,
                    (unsigned long)filtered.count,
                    filtered != original ? @"YES" : @"NO");
            
            if (filtered != original) {
                [self setValue:filtered forKey:@"_sectionRenderers"];
            }
        }
    } @catch (__unused NSException *exception) {
    }
    %orig;
}

- (void)addSectionsFromArray:(NSArray *)array {
    NSArray *filtered = [NTYTProductionFilter filteredSectionCollectionFromOriginal:array];

    NTYTLog(@"[Hook] addSectionsFromArray: input=%lu output=%lu changed=%@",
            (unsigned long)array.count,
            (unsigned long)filtered.count,
            filtered != array ? @"YES" : @"NO");

    %orig(filtered);
}

%end

%ctor {
    @autoreleasepool {
        NTYTLog(@"=== NoThankYouTube v1 loaded ===");
        NTYTLog(@"[Bootstrap] logFile = %@", [LogHelper logFilePath]);

        [NTYTSettingsCoordinator sharedCoordinator];
    }
}
