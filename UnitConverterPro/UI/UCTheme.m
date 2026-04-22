#import "UCTheme.h"

@implementation UCTheme

+ (UIColor *)backgroundColor {
    return [UIColor colorWithRed:0.95 green:0.96 blue:0.99 alpha:1.0];
}

+ (UIColor *)cardColor {
    return [UIColor whiteColor];
}

+ (UIColor *)primaryTint {
    return [UIColor colorWithRed:0.15 green:0.32 blue:0.98 alpha:1.0];
}

+ (UIColor *)secondaryText {
    return [UIColor colorWithRed:0.38 green:0.40 blue:0.50 alpha:1.0];
}

+ (UIColor *)colorFromHex:(NSString *)hex {
    unsigned int rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:[hex stringByReplacingOccurrencesOfString:@"#" withString:@""]];
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0
                           green:((rgbValue & 0x00FF00) >> 8)/255.0
                            blue:(rgbValue & 0x0000FF)/255.0
                           alpha:1.0];
}

@end
