#import <Foundation/Foundation.h>

#import <YouTubeHeader/YTInnerTubeCollectionViewController.h>

#import "NTYTSectionCollectionAdapter.h"
#import "Persistence/NTYTSettingsCoordinator.h"
#import "Debug/LogHelper.h"

%hook YTInnerTubeCollectionViewController

- (void)displaySectionsWithReloadingSectionControllerByRenderer:(id)renderer {
    @try {
        id originalValue = [self valueForKey:@"_sectionRenderers"];
        if ([originalValue isKindOfClass:[NSArray class]]) {
            NSArray *original = (NSArray *)originalValue;
            NSArray *filtered =
                [NTYTSectionCollectionAdapter filteredSectionCollectionFromOriginal:original];
            NTYTLog(@"[Hook] displaySections: input=%lu output=%lu outerChanged=%@",
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
    NSArray *filtered =
        [NTYTSectionCollectionAdapter filteredSectionCollectionFromOriginal:array];

    NTYTLog(@"[Hook] addSectionsFromArray: input=%lu output=%lu outerChanged=%@",
            (unsigned long)array.count,
            (unsigned long)filtered.count,
            filtered != array ? @"YES" : @"NO");

    %orig(filtered);
}

- (id)insertContents:(NSArray *)contents
          byPosition:(int)position
           inSection:(id)section
               error:(NSError **)error {
    NSArray *filtered = [NTYTSectionCollectionAdapter
        filteredStandaloneHorizontalContinuationContents:contents];
    // Always preserve the original position dispatch, model update, return and error path.
    return %orig(filtered, position, section, error);
}

%end

%ctor {
    @autoreleasepool {
        NTYTLog(@"=== NoThankYouTube v1 loaded ===");
        NTYTLog(@"[Bootstrap] logFile = %@", [LogHelper logFilePath]);

        [NTYTSettingsCoordinator sharedCoordinator];
    }
}
