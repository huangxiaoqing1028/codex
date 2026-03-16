#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SizePreset : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) CGSize mmSize;
@property (nonatomic, readonly) CGFloat aspectRatio;

+ (NSArray<SizePreset *> *)commonPresets;
+ (UIImage *)cropImage:(UIImage *)image toAspectRatio:(CGFloat)ratio;
@end
