#import "PDFResumeRenderer.h"
#import "../Models/ResumeData.h"

@interface ResumeHTMLPageRenderer : UIPrintPageRenderer
@end

@implementation ResumeHTMLPageRenderer

- (instancetype)init {
    self = [super init];
    if (self) {
        CGRect pageRect = CGRectMake(0, 0, 595, 842);
        CGRect printableRect = CGRectInset(pageRect, 22, 20);
        [self setValue:[NSValue valueWithCGRect:pageRect] forKey:@"paperRect"];
        [self setValue:[NSValue valueWithCGRect:printableRect] forKey:@"printableRect"];
    }
    return self;
}

@end

@implementation PDFResumeRenderer

+ (nullable NSURL *)renderPDFForResume:(ResumeData *)data {
    return [self renderPDFForResume:data templateIndex:0];
}

+ (nullable NSURL *)renderPDFForResume:(ResumeData *)data templateIndex:(NSInteger)templateIndex {
    NSURL *htmlURL = [self writeHTMLForResume:data templateIndex:templateIndex];
    if (!htmlURL) {
        return nil;
    }

    NSString *safeName = data.name.length > 0 ? data.name : @"Resume";
    return [self renderPDFFromHTMLAtURL:htmlURL outputFileName:[NSString stringWithFormat:@"%@_Template%ld.pdf", safeName, (long)(templateIndex + 1)]];
}

+ (nullable NSURL *)writeHTMLForResume:(ResumeData *)data templateIndex:(NSInteger)templateIndex {
    NSString *html = [self htmlForResume:data templateIndex:templateIndex];
    NSString *safeName = data.name.length > 0 ? data.name : @"Resume";
    NSString *fileName = [NSString stringWithFormat:@"%@_Template%ld.html", safeName, (long)(templateIndex + 1)];
    NSURL *url = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];

    NSError *error = nil;
    BOOL ok = [html writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (!ok || error) {
        return nil;
    }
    return url;
}

+ (nullable NSURL *)renderPDFFromHTMLAtURL:(NSURL *)htmlURL outputFileName:(NSString *)fileName {
    NSError *readError = nil;
    NSString *html = [NSString stringWithContentsOfURL:htmlURL encoding:NSUTF8StringEncoding error:&readError];
    if (readError || html.length == 0) {
        return nil;
    }

    NSURL *pdfURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
    UIMarkupTextPrintFormatter *formatter = [[UIMarkupTextPrintFormatter alloc] initWithMarkupText:html];

    ResumeHTMLPageRenderer *renderer = [[ResumeHTMLPageRenderer alloc] init];
    [renderer addPrintFormatter:formatter startingAtPageAtIndex:0];

    NSMutableData *pdfData = [NSMutableData data];
    UIGraphicsBeginPDFContextToData(pdfData, CGRectZero, nil);
    NSInteger pages = [renderer numberOfPages];
    for (NSInteger i = 0; i < pages; i++) {
        UIGraphicsBeginPDFPage();
        CGRect bounds = UIGraphicsGetPDFContextBounds();
        [renderer drawPageAtIndex:i inRect:bounds];
    }
    UIGraphicsEndPDFContext();

    NSError *writeError = nil;
    if (![pdfData writeToURL:pdfURL options:NSDataWritingAtomic error:&writeError] || writeError) {
        return nil;
    }
    return pdfURL;
}

+ (NSString *)htmlForResume:(ResumeData *)data templateIndex:(NSInteger)templateIndex {
    NSString *name = [self escape:data.name fallback:@"未命名候选人"];
    NSString *role = [self escape:data.targetRole fallback:@"目标岗位"];
    NSString *phone = [self escape:data.phone fallback:@"-"];
    NSString *email = [self escape:data.email fallback:@"-"];
    NSString *city = [self escape:data.city fallback:@"-"];
    NSString *portfolio = [self escape:data.portfolio fallback:@"-"];
    NSString *summary = [self escape:data.summary fallback:@"暂无"];

    NSString *eduList = [self listHTMLFromArray:data.education fallback:@"暂无"];
    NSString *expList = [self listHTMLFromArray:data.experiences fallback:@"暂无"];
    NSString *skillsList = [self listHTMLFromArray:data.skills fallback:@"暂无"];
    NSString *projectList = [self listHTMLFromArray:data.projects fallback:@"暂无"];

    NSString *templateName = templateIndex == 1 ? @"template_b" : @"template_a";
    NSString *templatePath = [[NSBundle mainBundle] pathForResource:templateName ofType:@"html" inDirectory:@"Templates"];

    NSString *templateHTML = nil;
    if (templatePath.length > 0) {
        templateHTML = [NSString stringWithContentsOfFile:templatePath encoding:NSUTF8StringEncoding error:nil];
    }

    if (templateHTML.length == 0) {
        templateHTML = templateIndex == 1 ? [self fallbackTemplateB] : [self fallbackTemplateA];
    }

    NSDictionary<NSString *, NSString *> *map = @{
        @"{{name}}": name,
        @"{{role}}": role,
        @"{{phone}}": phone,
        @"{{email}}": email,
        @"{{city}}": city,
        @"{{portfolio}}": portfolio,
        @"{{summary}}": summary,
        @"{{education_list}}": eduList,
        @"{{experiences_list}}": expList,
        @"{{skills_list}}": skillsList,
        @"{{projects_list}}": projectList
    };

    NSString *result = templateHTML;
    for (NSString *token in map) {
        result = [result stringByReplacingOccurrencesOfString:token withString:map[token]];
    }
    return result;
}

+ (NSString *)fallbackTemplateA {
    return @"<!doctype html><html><body><h1>{{name}}</h1><p>{{role}}</p><p>{{summary}}</p></body></html>";
}

+ (NSString *)fallbackTemplateB {
    return @"<!doctype html><html><body><h1>{{name}}</h1><p>{{role}}</p><ul>{{projects_list}}</ul></body></html>";
}

+ (NSString *)listHTMLFromArray:(NSArray<NSString *> *)items fallback:(NSString *)fallback {
    NSArray<NSString *> *source = items.count > 0 ? items : @[fallback];
    NSMutableArray<NSString *> *wrapped = [NSMutableArray arrayWithCapacity:source.count];
    for (NSString *line in source) {
        [wrapped addObject:[NSString stringWithFormat:@"<li>%@</li>", [self escape:line fallback:@"-"]]];
    }
    return [wrapped componentsJoinedByString:@""];
}

+ (NSString *)escape:(NSString *)raw fallback:(NSString *)fallback {
    NSString *value = raw.length > 0 ? raw : fallback;
    value = [value stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
    value = [value stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
    value = [value stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
    return value;
}

@end
