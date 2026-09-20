#import <Foundation/Foundation.h>

#import "NTYTTypes.h"

NS_ASSUME_NONNULL_BEGIN

@interface NTYTMatchOptions : NSObject <NSCopying>

@property(nonatomic, readonly) BOOL caseSensitive;
@property(nonatomic, readonly) BOOL exactMatch;

- (instancetype)initWithCaseSensitive:(BOOL)caseSensitive
                            exactMatch:(BOOL)exactMatch NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

@interface NTYTListDefinition : NSObject

@property(nonatomic, readonly) NTYTListID listID;
@property(nonatomic, readonly) NTYTListKind listKind;
@property(nonatomic, readonly) NTYTTargetKind targetKind;
@property(nonatomic, copy, readonly) NSArray<NSString *> *storagePath;
@property(nonatomic, copy, readonly) NSSet<NSNumber *> *supportedOptions;
@property(nonatomic, strong, readonly) NTYTMatchOptions *defaultOptions;

- (BOOL)supportsOption:(NTYTListOptionID)optionID;
- (BOOL)defaultValueForOption:(NTYTListOptionID)optionID;

+ (NSArray<NTYTListDefinition *> *)allDefinitions;
+ (nullable NTYTListDefinition *)definitionForListID:(NTYTListID)listID;

@end

NS_ASSUME_NONNULL_END
