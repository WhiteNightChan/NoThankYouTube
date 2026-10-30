#import <Foundation/Foundation.h>

#import "NTYTTypes.h"

NS_ASSUME_NONNULL_BEGIN

// Complete effective state. Sparse persistence is resolved before this model is built.
@interface NTYTBlockOptionState : NSObject

@property(nonatomic, readonly) BOOL blockShorts;
@property(nonatomic, readonly) BOOL blockPost;
@property(nonatomic, readonly) BOOL blockPlaylist;
@property(nonatomic, readonly) BOOL blockMix;
@property(nonatomic, readonly) BOOL blockHorizontalShelf;
@property(nonatomic, readonly) BOOL blockFromYouTube;
@property(nonatomic, readonly) BOOL blockAdSupportedFreeMovie;
@property(nonatomic, readonly) BOOL blockCellDivider;
@property(nonatomic, readonly) BOOL blockStation;

- (instancetype)initWithBlockShorts:(BOOL)blockShorts
                          blockPost:(BOOL)blockPost
                      blockPlaylist:(BOOL)blockPlaylist
                           blockMix:(BOOL)blockMix
               blockHorizontalShelf:(BOOL)blockHorizontalShelf
                   blockFromYouTube:(BOOL)blockFromYouTube
          blockAdSupportedFreeMovie:(BOOL)blockAdSupportedFreeMovie
                   blockCellDivider:(BOOL)blockCellDivider
                       blockStation:(BOOL)blockStation NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
- (BOOL)valueForOption:(NTYTBlockOptionID)optionID;
+ (instancetype)allOffState;

@end

NS_ASSUME_NONNULL_END
