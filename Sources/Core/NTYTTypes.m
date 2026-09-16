#import "NTYTTypes.h"

NTYTMatchResult NTYTNegateMatchResult(NTYTMatchResult result) {
    switch (result) {
        case NTYTMatchResultMatch:
            return NTYTMatchResultNoMatch;
        case NTYTMatchResultNoMatch:
            return NTYTMatchResultMatch;
        case NTYTMatchResultUnavailable:
            return NTYTMatchResultUnavailable;
    }
    return NTYTMatchResultUnavailable;
}

NSString *NTYTSettingsLifecycleDescription(NTYTSettingsLifecycleState state) {
    switch (state) {
        case NTYTSettingsLifecycleStateAbsent:
            return @"Absent";
        case NTYTSettingsLifecycleStateSupportedValid:
            return @"Supported / Valid";
        case NTYTSettingsLifecycleStateSupportedDegraded:
            return @"Supported / Degraded";
        case NTYTSettingsLifecycleStateUnusable:
            return @"Unusable";
    }
    return @"Unknown";
}
