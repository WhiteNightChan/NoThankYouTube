#import <Foundation/Foundation.h>

#import <YouTubeHeader/YTInnerTubeCollectionViewController.h>

#import "NTYTProductionFilter.h"
#import "Persistence/NTYTSettingsCoordinator.h"

%hook YTInnerTubeCollectionViewController

- (void)displaySectionsWithReloadingSectionControllerByRenderer:(id)renderer {
    @try {
        id originalValue = [self valueForKey:@"_sectionRenderers"];
        if ([originalValue isKindOfClass:[NSArray class]]) {
            NSArray *original = (NSArray *)originalValue;
            NSArray *filtered =
                [NTYTProductionFilter filteredSectionCollectionFromOriginal:original];
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
    %orig(filtered);
}

%end

%ctor {
    @autoreleasepool {
        [NTYTSettingsCoordinator sharedCoordinator];
    }
}
