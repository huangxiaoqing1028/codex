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
    NSString *safeName = data.name.length > 0 ? data.name : @"Resume";
    NSString *fileName = [NSString stringWithFormat:@"%@_Template%ld.pdf", safeName, (long)(templateIndex + 1)];
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
    NSURL *url = [NSURL fileURLWithPath:path];

    NSString *html = [self htmlForResume:data templateIndex:templateIndex];
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
    if (![pdfData writeToURL:url options:NSDataWritingAtomic error:&writeError] || writeError) {
        return nil;
    }
    return url;
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

    if (templateIndex == 1) {
        return [NSString stringWithFormat:@"<!doctype html><html><head><meta charset='UTF-8'><style>%@</style></head><body>"
                "<div class='sheet modern'>"
                "<header><div><h1>%@</h1><h2>%@</h2></div><div class='pill'>Resume Template B</div></header>"
                "<section class='info-grid'><div><label>电话</label><p>%@</p></div><div><label>邮箱</label><p>%@</p></div><div><label>城市</label><p>%@</p></div><div><label>作品集</label><p>%@</p></div></section>"
                "<section><h3>个人简介</h3><p>%@</p></section>"
                "<section><h3>工作经历</h3><ul>%@</ul></section>"
                "<section class='double'><div><h3>教育背景</h3><ul>%@</ul></div><div><h3>核心技能</h3><ul>%@</ul></div></section>"
                "<section><h3>项目亮点</h3><ul>%@</ul></section>"
                "</div></body></html>",
                [self templateStyleB], name, role, phone, email, city, portfolio, summary, expList, eduList, skillsList, projectList];
    }

    return [NSString stringWithFormat:@"<!doctype html><html><head><meta charset='UTF-8'><style>%@</style></head><body>"
            "<div class='sheet classic'><aside><h1>%@</h1><p class='role'>%@</p><div class='meta'><h4>联系方式</h4><p>电话 %@</p><p>邮箱 %@</p><p>城市 %@</p><p>作品集 %@</p></div><div class='meta'><h4>核心技能</h4><ul>%@</ul></div></aside>"
            "<main><section><h3>个人简介</h3><p>%@</p></section><section><h3>工作经历</h3><ul>%@</ul></section><section><h3>教育背景</h3><ul>%@</ul></section><section><h3>项目亮点</h3><ul>%@</ul></section></main></div>"
            "</body></html>",
            [self templateStyleA], name, role, phone, email, city, portfolio, skillsList, summary, expList, eduList, projectList];
}

+ (NSString *)templateStyleA {
    return @"*{box-sizing:border-box;}body{font-family:-apple-system,BlinkMacSystemFont,'PingFang SC','Helvetica Neue',sans-serif;margin:0;background:#eef2ff;color:#111827;}"
    ".sheet{width:100%;min-height:100vh;display:flex;background:#fff;}"
    ".classic aside{width:34%;background:linear-gradient(180deg,#243b8f,#1f2a5f);color:#fff;padding:26px 20px;}"
    ".classic main{width:66%;padding:24px;}h1{margin:0;font-size:30px;}h2,.role{margin:8px 0 0;font-size:15px;opacity:.95;}"
    ".meta{margin-top:20px;}h4{margin:0 0 8px;font-size:12px;letter-spacing:.4px;text-transform:uppercase;color:#c7d2fe;}"
    ".meta p{margin:4px 0;font-size:12px;line-height:1.5;}section{margin-bottom:16px;background:#f8faff;border:1px solid #dbe6ff;border-radius:12px;padding:12px 14px;}"
    "h3{margin:0 0 8px;color:#1f3a8a;font-size:15px;}p,li{font-size:12px;line-height:1.6;margin:0;}ul{margin:0;padding-left:18px;}li{margin-bottom:4px;}";
}

+ (NSString *)templateStyleB {
    return @"*{box-sizing:border-box;}body{font-family:-apple-system,BlinkMacSystemFont,'PingFang SC','Helvetica Neue',sans-serif;margin:0;background:#f5f7fb;color:#101828;}"
    ".sheet{padding:24px 26px;}header{display:flex;justify-content:space-between;align-items:flex-start;padding:18px 20px;border-radius:16px;background:linear-gradient(135deg,#0f172a,#2563eb);color:#fff;}"
    "h1{margin:0;font-size:32px;}h2{margin:8px 0 0;font-size:16px;font-weight:500;color:#dbeafe;}"
    ".pill{font-size:11px;background:rgba(255,255,255,.16);padding:8px 10px;border-radius:999px;}"
    ".info-grid{margin-top:14px;display:grid;grid-template-columns:1fr 1fr;gap:10px;}"
    ".info-grid div{background:#fff;border:1px solid #d7e3ff;border-radius:12px;padding:10px 12px;}label{font-size:11px;color:#637087;text-transform:uppercase;letter-spacing:.4px;}"
    ".info-grid p{margin:4px 0 0;font-size:13px;font-weight:600;color:#0f172a;}section{margin-top:12px;background:#fff;border:1px solid #d7e3ff;border-radius:14px;padding:12px 14px;}"
    "h3{margin:0 0 8px;color:#1d4ed8;font-size:15px;}p,li{font-size:12px;line-height:1.6;margin:0;}ul{margin:0;padding-left:18px;}"
    ".double{display:grid;grid-template-columns:1fr 1fr;gap:12px;}";
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
