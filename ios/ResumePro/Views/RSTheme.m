#import "RSTheme.h"

@implementation RSTheme

+ (UIColor *)bgPrimary { return [UIColor colorWithRed:0.06 green:0.07 blue:0.10 alpha:1.0]; }
+ (UIColor *)bgSecondary { return [UIColor colorWithRed:0.10 green:0.11 blue:0.15 alpha:1.0]; }
+ (UIColor *)cardBackground { return [UIColor colorWithRed:0.12 green:0.13 blue:0.18 alpha:1.0]; }
+ (UIColor *)accentGold { return [UIColor colorWithRed:0.78 green:0.64 blue:0.42 alpha:1.0]; }
+ (UIColor *)textPrimary { return [UIColor colorWithRed:0.96 green:0.96 blue:0.97 alpha:1.0]; }
+ (UIColor *)textSecondary { return [UIColor colorWithRed:0.73 green:0.74 blue:0.78 alpha:1.0]; }
+ (UIColor *)border { return [UIColor colorWithWhite:1 alpha:0.08]; }

+ (UIFont *)titleFont { return [UIFont systemFontOfSize:24 weight:UIFontWeightBold]; }
+ (UIFont *)subtitleFont { return [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold]; }
+ (UIFont *)bodyFont { return [UIFont systemFontOfSize:14 weight:UIFontWeightRegular]; }

@end
