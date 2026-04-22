#import "RSTemplateService.h"
#import "RSTemplate.h"

@implementation RSTemplateService

+ (instancetype)shared {
    static RSTemplateService *svc;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ svc = [[RSTemplateService alloc] init]; });
    return svc;
}

- (NSArray<RSTemplate *> *)allTemplates {
    return @[
        [RSTemplate templateWithId:@"business_dark"
                              name:@"商务深色"
                           premium:NO
                   backgroundColor:[self color:@"#111827"]
                        titleColor:[UIColor whiteColor]
                         bodyColor:[self color:@"#E5E7EB"]],
        [RSTemplate templateWithId:@"business_light"
                              name:@"商务浅色"
                           premium:NO
                   backgroundColor:[UIColor colorWithWhite:0.98 alpha:1]
                        titleColor:[self color:@"#111827"]
                         bodyColor:[UIColor darkGrayColor]],
        [RSTemplate templateWithId:@"executive_gold"
                              name:@"高管金"
                           premium:YES
                   backgroundColor:[self color:@"#0F1115"]
                        titleColor:[self color:@"#C7A26A"]
                         bodyColor:[UIColor colorWithWhite:0.9 alpha:1]],
        [RSTemplate templateWithId:@"consulting_gray"
                              name:@"咨询灰"
                           premium:YES
                   backgroundColor:[self color:@"#1F2937"]
                        titleColor:[self color:@"#F3F4F6"]
                         bodyColor:[self color:@"#D1D5DB"]],
        [RSTemplate templateWithId:@"modern_blue"
                              name:@"现代蓝"
                           premium:YES
                   backgroundColor:[self color:@"#0B1F3A"]
                        titleColor:[self color:@"#93C5FD"]
                         bodyColor:[self color:@"#E0F2FE"]],
    ];
}

- (RSTemplate *)templateById:(NSString *)templateId {
    for (RSTemplate *item in [self allTemplates]) {
        if ([item.templateId isEqualToString:templateId]) { return item; }
    }
    return [self allTemplates].firstObject;
}

- (UIColor *)color:(NSString *)hex {
    unsigned int rgb = 0;
    NSScanner *scanner = [NSScanner scannerWithString:[hex stringByReplacingOccurrencesOfString:@"#" withString:@""]];
    [scanner scanHexInt:&rgb];
    return [UIColor colorWithRed:((rgb >> 16) & 0xFF)/255.0
                           green:((rgb >> 8) & 0xFF)/255.0
                            blue:(rgb & 0xFF)/255.0
                           alpha:1.0];
}

@end
