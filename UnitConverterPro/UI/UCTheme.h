#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UCTheme : NSObject

+ (UIColor *)backgroundColor;
+ (UIColor *)cardColor;
+ (UIColor *)primaryTint;
+ (UIColor *)secondaryText;
+ (UIColor *)colorFromHex:(NSString *)hex;

@end

NS_ASSUME_NONNULL_END
