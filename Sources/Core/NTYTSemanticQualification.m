#import "NTYTSemanticQualification.h"

@implementation NTYTSemanticQualificationResult

- (instancetype)initWithContentFamily:(NTYTContentFamily)contentFamily
                      playlistSubtype:(NTYTPlaylistSubtype)playlistSubtype
                 shortsClassification:(NTYTShortsClassification)shortsClassification
                      horizontalShelf:(NTYTPresentationQualification)horizontalShelf
             horizontalShelfException:(NTYTHorizontalShelfException)horizontalShelfException
                          shortsShelf:(NTYTPresentationQualification)shortsShelf
                      fromYouTubeCell:(NTYTPresentationQualification)fromYouTubeCell
                 adSupportedFreeMovie:(NTYTPresentationQualification)adSupportedFreeMovie
                          cellDivider:(NTYTPresentationQualification)cellDivider {
    self = [super init];
    if (self) {
        _contentFamily = contentFamily;
        _playlistSubtype = playlistSubtype;
        _shortsClassification = shortsClassification;
        _horizontalShelf = horizontalShelf;
        _horizontalShelfException = horizontalShelfException;
        _shortsShelf = shortsShelf;
        _fromYouTubeCell = fromYouTubeCell;
        _adSupportedFreeMovie = adSupportedFreeMovie;
        _cellDivider = cellDivider;
    }
    return self;
}

- (NTYTContentType)projectedContentType {
    switch (self.contentFamily) {
        case NTYTContentFamilyVideo: return NTYTContentTypeVideo;
        case NTYTContentFamilyPost: return NTYTContentTypePost;
        case NTYTContentFamilyPlaylist:
            if (self.playlistSubtype == NTYTPlaylistSubtypeNormal) return NTYTContentTypePlaylistNormal;
            if (self.playlistSubtype == NTYTPlaylistSubtypeMix) return NTYTContentTypePlaylistMix;
            return NTYTContentTypeUnresolved;
        case NTYTContentFamilyUnresolved: return NTYTContentTypeUnresolved;
    }
    return NTYTContentTypeUnresolved;
}

@end
