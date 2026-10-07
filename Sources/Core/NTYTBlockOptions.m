#import "NTYTBlockOptions.h"

@implementation NTYTBlockOptions

- (instancetype)initWithBlockShorts:(BOOL)blockShorts
                          blockPost:(BOOL)blockPost
                      blockPlaylist:(BOOL)blockPlaylist
                           blockMix:(BOOL)blockMix
               blockHorizontalShelf:(BOOL)blockHorizontalShelf
                   blockFromYouTube:(BOOL)blockFromYouTube {
    self = [super init];
    if (self) {
        _blockShorts = blockShorts;
        _blockPost = blockPost;
        _blockPlaylist = blockPlaylist;
        _blockMix = blockMix;
        _blockHorizontalShelf = blockHorizontalShelf;
        _blockFromYouTube = blockFromYouTube;
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
    }
    NSAssert(NO, @"Invalid BlockOptionID");
    return NO;
}

+ (instancetype)allOffOptions {
    static NTYTBlockOptions *options;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options = [[self alloc] initWithBlockShorts:NO blockPost:NO blockPlaylist:NO
                                         blockMix:NO blockHorizontalShelf:NO blockFromYouTube:NO];
    });
    return options;
}

@end
