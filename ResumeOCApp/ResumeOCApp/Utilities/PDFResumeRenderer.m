#import "PDFResumeRenderer.h"
#import "../Models/ResumeData.h"

@implementation PDFResumeRenderer

+ (NSURL *)renderPDFForResume:(ResumeData *)data {
    NSString *fileName = data.name.length > 0 ? [NSString stringWithFormat:@"%@_Resume.pdf", data.name] : @"Resume.pdf";
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
    NSURL *url = [NSURL fileURLWithPath:path];

    CGRect pageRect = CGRectMake(0, 0, 595, 842);
    UIGraphicsPDFRendererFormat *format = [[UIGraphicsPDFRendererFormat alloc] init];
    UIGraphicsPDFRenderer *renderer = [[UIGraphicsPDFRenderer alloc] initWithBounds:pageRect format:format];

    [renderer writePDFToURL:url withActions:^(UIGraphicsPDFRendererContext * _Nonnull context) {
        [context beginPage];
        CGContextRef cg = context.CGContext;

        [[UIColor colorWithRed:0.10 green:0.18 blue:0.45 alpha:1.0] setFill];
        CGContextFillRect(cg, CGRectMake(0, 0, 170, 842));

        NSDictionary *whiteTitle = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:24], NSForegroundColorAttributeName: UIColor.whiteColor};
        NSDictionary *whiteText = @{NSFontAttributeName: [UIFont systemFontOfSize:12], NSForegroundColorAttributeName: UIColor.whiteColor};
        NSDictionary *sectionTitle = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:14], NSForegroundColorAttributeName: [UIColor colorWithRed:0.22 green:0.30 blue:0.78 alpha:1.0]};
        NSDictionary *bodyText = @{NSFontAttributeName: [UIFont systemFontOfSize:11], NSForegroundColorAttributeName: [UIColor colorWithRed:0.15 green:0.16 blue:0.20 alpha:1.0]};

        [data.name.length > 0 ? data.name : @"未命名候选人" drawAtPoint:CGPointMake(18, 30) withAttributes:whiteTitle];
        [data.targetRole.length > 0 ? data.targetRole : @"目标岗位" drawAtPoint:CGPointMake(18, 64) withAttributes:whiteText];

        CGFloat sideY = 110;
        NSArray *contact = @[
            [NSString stringWithFormat:@"电话: %@", data.phone.length > 0 ? data.phone : @"-"],
            [NSString stringWithFormat:@"邮箱: %@", data.email.length > 0 ? data.email : @"-"],
            [NSString stringWithFormat:@"城市: %@", data.city.length > 0 ? data.city : @"-"],
            [NSString stringWithFormat:@"作品集: %@", data.portfolio.length > 0 ? data.portfolio : @"-"]
        ];

        for (NSString *line in contact) {
            [line drawInRect:CGRectMake(18, sideY, 140, 40) withAttributes:whiteText];
            sideY += 28;
        }

        [@"核心技能" drawAtPoint:CGPointMake(18, sideY + 8) withAttributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:13], NSForegroundColorAttributeName: UIColor.whiteColor}];
        sideY += 34;
        for (NSString *skill in data.skills) {
            NSString *line = [NSString stringWithFormat:@"• %@", skill];
            [line drawInRect:CGRectMake(18, sideY, 140, 30) withAttributes:whiteText];
            sideY += 22;
            if (sideY > 790) { break; }
        }

        CGFloat x = 190;
        CGFloat y = 40;
        CGFloat width = 370;

        y = [self drawSection:@"个人简介" content:@[data.summary.length > 0 ? data.summary : @"暂无"] x:x y:y width:width titleAttr:sectionTitle bodyAttr:bodyText];
        y = [self drawSection:@"工作经历" content:data.experiences.count > 0 ? data.experiences : @[@"暂无"] x:x y:y width:width titleAttr:sectionTitle bodyAttr:bodyText];
        y = [self drawSection:@"教育背景" content:data.education.count > 0 ? data.education : @[@"暂无"] x:x y:y width:width titleAttr:sectionTitle bodyAttr:bodyText];
        [self drawSection:@"项目亮点" content:data.projects.count > 0 ? data.projects : @[@"暂无"] x:x y:y width:width titleAttr:sectionTitle bodyAttr:bodyText];
    }];

    return url;
}

+ (CGFloat)drawSection:(NSString *)title
               content:(NSArray<NSString *> *)content
                     x:(CGFloat)x
                     y:(CGFloat)y
                 width:(CGFloat)width
              titleAttr:(NSDictionary<NSAttributedStringKey, id> *)titleAttr
               bodyAttr:(NSDictionary<NSAttributedStringKey, id> *)bodyAttr {
    [title drawAtPoint:CGPointMake(x, y) withAttributes:titleAttr];
    y += 24;

    for (NSString *item in content) {
        NSString *line = [NSString stringWithFormat:@"• %@", item];
        CGRect box = CGRectMake(x, y, width, 200);
        CGRect drawn = [line boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                                          options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                       attributes:bodyAttr
                                          context:nil];
        [line drawInRect:box withAttributes:bodyAttr];
        y += MAX(22, CGRectGetHeight(drawn) + 8);
    }

    y += 10;
    return y;
}

@end
