#import <Foundation/Foundation.h>

#import "NTYTTypes.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NTYTContentFamily) {
    NTYTContentFamilyUnresolved = 0,
    NTYTContentFamilyVideo,
    NTYTContentFamilyPost,
    NTYTContentFamilyPlaylist,
};

typedef NS_ENUM(NSInteger, NTYTPlaylistSubtype) {
    NTYTPlaylistSubtypeUnresolved = 0,
    NTYTPlaylistSubtypeNormal,
    NTYTPlaylistSubtypeMix,
};

typedef NS_ENUM(NSInteger, NTYTPresentationQualification) {
    NTYTPresentationQualificationUnavailable = 0,
    NTYTPresentationQualificationNotConfirmed,
    NTYTPresentationQualificationConfirmed,
};

typedef NS_ENUM(NSInteger, NTYTHorizontalShelfException) {
    NTYTHorizontalShelfExceptionUnavailable = 0,
    NTYTHorizontalShelfExceptionHistory,
    NTYTHorizontalShelfExceptionPlaylist,
    NTYTHorizontalShelfExceptionOther,
};

@interface NTYTSemanticQualificationResult : NSObject

@property(nonatomic, readonly) NTYTContentFamily contentFamily;
@property(nonatomic, readonly) NTYTPlaylistSubtype playlistSubtype;
@property(nonatomic, readonly) NTYTShortsClassification shortsClassification;
@property(nonatomic, readonly) NTYTPresentationQualification horizontalShelf;
@property(nonatomic, readonly) NTYTHorizontalShelfException horizontalShelfException;
@property(nonatomic, readonly) NTYTPresentationQualification shortsShelf;
@property(nonatomic, readonly) NTYTPresentationQualification fromYouTubeCell;
@property(nonatomic, readonly) NTYTContentType projectedContentType;

- (instancetype)initWithContentFamily:(NTYTContentFamily)contentFamily
                      playlistSubtype:(NTYTPlaylistSubtype)playlistSubtype
                 shortsClassification:(NTYTShortsClassification)shortsClassification
                      horizontalShelf:(NTYTPresentationQualification)horizontalShelf
             horizontalShelfException:(NTYTHorizontalShelfException)horizontalShelfException
                          shortsShelf:(NTYTPresentationQualification)shortsShelf
                      fromYouTubeCell:(NTYTPresentationQualification)fromYouTubeCell NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
