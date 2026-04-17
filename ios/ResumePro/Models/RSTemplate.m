#import "RSTemplate.h"

@implementation RSTemplate

+ (instancetype)templateWithId:(NSString *)templateId
                          name:(NSString *)name
                       premium:(BOOL)premium
               backgroundColor:(UIColor *)backgroundColor
                    titleColor:(UIColor *)titleColor
                     bodyColor:(UIColor *)bodyColor {
    RSTemplate *item = [[RSTemplate alloc] init];
    item.templateId = templateId;
    item.name = name;
    item.premium = premium;
    item.backgroundColor = backgroundColor;
    item.titleColor = titleColor;
    item.bodyColor = bodyColor;
    return item;
}

@end
