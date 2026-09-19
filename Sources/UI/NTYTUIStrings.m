#import "NTYTUIStrings.h"

NSString *NTYTListTitle(NTYTListID listID) {
    switch (listID) {
        case NTYTListIDGeneralBlock:
            return @"Block";
        case NTYTListIDGeneralAllow:
            return @"Allow";
        case NTYTListIDVideosTitle:
            return @"Title";
        case NTYTListIDVideosChannel:
            return @"Channel";
        case NTYTListIDVideosID:
            return @"Video ID";
        case NTYTListIDChannelsBlock:
            return @"Block";
        case NTYTListIDChannelsAllow:
            return @"Allow";
    }
    return @"Rules";
}

NSString *NTYTCategoryTitle(NSUInteger categoryIndex) {
    switch (categoryIndex) {
        case 0:
            return @"General";
        case 1:
            return @"Videos";
        case 2:
            return @"Channels";
        default:
            return @"NoThankYouTube";
    }
}

NSString *NTYTOptionTitle(NTYTListOptionID optionID) {
    switch (optionID) {
        case NTYTListOptionIDCaseSensitive:
            return @"Case Sensitive";
        case NTYTListOptionIDExactMatch:
            return @"Exact Match";
    }
    return @"Option";
}

NSString *NTYTAddTitle(void) { return @"Add Rule"; }
NSString *NTYTEditTitle(void) { return @"Edit Rule"; }
NSString *NTYTSearchPlaceholder(void) { return @"Search rules"; }
NSString *NTYTInputMessage(void) { return @"Enter one raw rule expression."; }
NSString *NTYTInputPlaceholder(void) { return @"Rule expression"; }
NSString *NTYTEmptyListText(void) { return @"No rules"; }
NSString *NTYTNoResultsText(void) { return @"No matching rules"; }

NSString *NTYTDeleteTitle(NSUInteger count) {
    return count == 1 ? @"Delete Rule?" : [NSString stringWithFormat:@"Delete %lu Rules?", (unsigned long)count];
}

NSString *NTYTDeleteMessage(NSUInteger count, NSString *expression) {
    if (count == 1 && expression.length > 0) {
        return expression;
    }
    return @"This operation cannot be undone.";
}
