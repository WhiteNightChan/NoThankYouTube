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
            NSArray *sectionRenderers = (NSArray *)originalValue;
            [NTYTSectionCollectionAdapter filterSectionCollection:sectionRenderers];
        }
    } @catch (__unused NSException *exception) {
    }
    %orig;
}

- (void)addSectionsFromArray:(NSArray *)array {
    [NTYTSectionCollectionAdapter filterSectionCollection:array];

    %orig(array);
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
