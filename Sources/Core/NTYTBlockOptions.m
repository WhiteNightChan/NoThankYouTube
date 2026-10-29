#import "NTYTBlockOptions.h"

@implementation NTYTBlockOptions

- (instancetype)initWithBlockShorts:(BOOL)blockShorts
                          blockPost:(BOOL)blockPost
                      blockPlaylist:(BOOL)blockPlaylist
                           blockMix:(BOOL)blockMix
               blockHorizontalShelf:(BOOL)blockHorizontalShelf
                   blockFromYouTube:(BOOL)blockFromYouTube
          blockAdSupportedFreeMovie:(BOOL)blockAdSupportedFreeMovie
                   blockCellDivider:(BOOL)blockCellDivider
                       blockStation:(BOOL)blockStation {
    self = [super init];
    if (self) {
        _blockShorts = blockShorts;
        _blockPost = blockPost;
        _blockPlaylist = blockPlaylist;
        _blockMix = blockMix;
        _blockHorizontalShelf = blockHorizontalShelf;
        _blockFromYouTube = blockFromYouTube;
        _blockAdSupportedFreeMovie = blockAdSupportedFreeMovie;
        _blockCellDivider = blockCellDivider;
        _blockStation = blockStation;
    }
    return self;
}

- (BOOL)valueForOption:(NTYTBlockOptionID)optionID {
    switch (optionID) {
        case NTYTBlockOptionIDShorts: return self.blockShorts;
        case NTYTBlockOptionIDPost: return self.blockPost;
        case NTYTBlockOptionIDPlaylist: return self.blockPlaylist;
        case NTYTBlockOptionIDMix: return self.blockMix;
        case NTYTBlockOptionIDHorizontalShelf: return self.blockHorizontalShelf;
        case NTYTBlockOptionIDFromYouTube: return self.blockFromYouTube;
        case NTYTBlockOptionIDAdSupportedFreeMovie: return self.blockAdSupportedFreeMovie;
        case NTYTBlockOptionIDCellDivider: return self.blockCellDivider;
        case NTYTBlockOptionIDStation: return self.blockStation;
    }
    NSAssert(NO, @"Invalid BlockOptionID");
    return NO;
}

+ (instancetype)allOffOptions {
    static NTYTBlockOptions *options;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options = [[self alloc] initWithBlockShorts:NO blockPost:NO blockPlaylist:NO
                                         blockMix:NO blockHorizontalShelf:NO blockFromYouTube:NO
                         blockAdSupportedFreeMovie:NO blockCellDivider:NO blockStation:NO];
    });
    return options;
}

@end
