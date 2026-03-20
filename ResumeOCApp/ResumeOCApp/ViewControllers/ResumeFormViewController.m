#import "ResumeFormViewController.h"
#import "../Models/ResumeData.h"
#import "../Utilities/PDFResumeRenderer.h"
#import <WebKit/WebKit.h>

@interface ResumeHTMLPreviewController : UIViewController
- (instancetype)initWithHTMLURL:(NSURL *)htmlURL fileName:(NSString *)fileName;
@end

@interface ResumeHTMLPreviewController ()
@property (nonatomic, strong) NSURL *htmlURL;
@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, strong) WKWebView *webView;
@end

@implementation ResumeHTMLPreviewController

- (instancetype)initWithHTMLURL:(NSURL *)htmlURL fileName:(NSString *)fileName {
    self = [super init];
    if (self) {
        _htmlURL = htmlURL;
        _fileName = fileName;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"简历 HTML 预览";
    self.view.backgroundColor = [UIColor colorWithRed:0.95 green:0.97 blue:1 alpha:1.0];

    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    self.webView.backgroundColor = UIColor.clearColor;
    self.webView.scrollView.contentInset = UIEdgeInsetsMake(12, 12, 16, 12);
    [self.view addSubview:self.webView];

    [NSLayoutConstraint activateConstraints:@[
        [self.webView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.webView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.webView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.webView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    [self.webView loadFileURL:self.htmlURL allowingReadAccessToURL:self.htmlURL.URLByDeletingLastPathComponent];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"导出PDF"
                                                                               style:UIBarButtonItemStyleDone
                                                                              target:self
                                                                              action:@selector(exportPDFTapped)];
}

- (void)exportPDFTapped {
    NSURL *pdfURL = [PDFResumeRenderer renderPDFFromHTMLAtURL:self.htmlURL outputFileName:self.fileName];
    if (!pdfURL) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"导出失败" message:@"HTML 转 PDF 失败，请稍后重试。" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }

    UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:@[pdfURL] applicationActivities:nil];
    if (activity.popoverPresentationController) {
        activity.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItem;
    }
    [self presentViewController:activity animated:YES completion:nil];
}

@end

@interface ResumeFormViewController () <UITextViewDelegate, UIScrollViewDelegate>
@property (nonatomic, strong) UIScrollView *pagesScrollView;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, strong) UIButton *previewPDFButton;
@property (nonatomic, strong) NSMutableDictionary<NSString *, UIView *> *inputs;
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *placeholders;
@property (nonatomic, strong) UISegmentedControl *templateControl;
@end

@implementation ResumeFormViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"简历生成器 Pro";
    self.view.backgroundColor = [UIColor colorWithRed:0.95 green:0.97 blue:1 alpha:1.0];
    self.inputs = [NSMutableDictionary dictionary];
    self.placeholders = @{
        @"summary": @"一句话介绍你的优势、经验与价值主张",
        @"education": @"每行一条，例如：2016-2020 XXX大学 本科",
        @"experiences": @"每段空行分隔，描述成果时尽量量化",
        @"projects": @"每行一个项目亮点"
    };
    [self buildUI];
}

- (void)buildUI {
    self.pagesScrollView = [[UIScrollView alloc] init];
    self.pagesScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.pagesScrollView.pagingEnabled = YES;
    self.pagesScrollView.showsHorizontalScrollIndicator = NO;
    self.pagesScrollView.delegate = self;
    [self.view addSubview:self.pagesScrollView];

    self.pageControl = [[UIPageControl alloc] init];
    self.pageControl.translatesAutoresizingMaskIntoConstraints = NO;
    self.pageControl.numberOfPages = 6;
    self.pageControl.currentPage = 0;
    self.pageControl.currentPageIndicatorTintColor = [UIColor colorWithRed:0.26 green:0.33 blue:1 alpha:1];
    self.pageControl.pageIndicatorTintColor = [UIColor colorWithRed:0.76 green:0.80 blue:0.95 alpha:1];
    [self.view addSubview:self.pageControl];

    [NSLayoutConstraint activateConstraints:@[
        [self.pagesScrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:12],
        [self.pagesScrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.pagesScrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.pagesScrollView.bottomAnchor constraintEqualToAnchor:self.pageControl.topAnchor constant:-12],

        [self.pageControl.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.pageControl.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.pageControl.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-8],
        [self.pageControl.heightAnchor constraintEqualToConstant:24]
    ]];

    UIStackView *pagesStack = [[UIStackView alloc] init];
    pagesStack.axis = UILayoutConstraintAxisHorizontal;
    pagesStack.spacing = 0;
    pagesStack.distribution = UIStackViewDistributionFillEqually;
    pagesStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.pagesScrollView addSubview:pagesStack];

    [NSLayoutConstraint activateConstraints:@[
        [pagesStack.topAnchor constraintEqualToAnchor:self.pagesScrollView.contentLayoutGuide.topAnchor],
        [pagesStack.leadingAnchor constraintEqualToAnchor:self.pagesScrollView.contentLayoutGuide.leadingAnchor],
        [pagesStack.trailingAnchor constraintEqualToAnchor:self.pagesScrollView.contentLayoutGuide.trailingAnchor],
        [pagesStack.bottomAnchor constraintEqualToAnchor:self.pagesScrollView.contentLayoutGuide.bottomAnchor],
        [pagesStack.heightAnchor constraintEqualToAnchor:self.pagesScrollView.frameLayoutGuide.heightAnchor]
    ]];

    NSArray<UIView *> *pages = @[
        [self pageForBasicInfo],
        [self pageWithTitle:@"简介" fields:@[[self textView:@"summary" placeholder:self.placeholders[@"summary"]]]],
        [self pageWithTitle:@"教育" fields:@[[self textView:@"education" placeholder:self.placeholders[@"education"]]]],
        [self pageWithTitle:@"工作经历" fields:@[[self textView:@"experiences" placeholder:self.placeholders[@"experiences"]]]],
        [self pageWithTitle:@"技能" fields:@[[self textField:@"skills" placeholder:@"核心技能，逗号分隔"]]],
        [self pageForProjectsAndActions]
    ];

    for (UIView *page in pages) {
        [pagesStack addArrangedSubview:page];
        [[page.widthAnchor constraintEqualToAnchor:self.pagesScrollView.frameLayoutGuide.widthAnchor] setActive:YES];
    }
}

- (UIView *)pageForBasicInfo {
    return [self pageWithTitle:@"基本信息" fields:@[
        [self textField:@"name" placeholder:@"姓名"],
        [self textField:@"targetRole" placeholder:@"应聘岗位"],
        [self textField:@"phone" placeholder:@"手机号"],
        [self textField:@"email" placeholder:@"邮箱"],
        [self textField:@"city" placeholder:@"所在城市"],
        [self textField:@"portfolio" placeholder:@"作品集链接"]
    ]];
}

- (UIView *)pageForProjectsAndActions {
    UIView *page = [self pageWithTitle:@"项目亮点" fields:@[
        [self textView:@"projects" placeholder:self.placeholders[@"projects"]]
    ]];

    UIStackView *container = [self findContainerStackInPage:page];
    if (!container) {
        return page;
    }

    UILabel *tip = [[UILabel alloc] init];
    tip.text = @"选择模板后，先预览 HTML 版简历；确认后可在右上角导出 PDF。";
    tip.numberOfLines = 0;
    tip.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    tip.textColor = [UIColor colorWithRed:0.33 green:0.35 blue:0.43 alpha:1.0];
    [container addArrangedSubview:tip];

    self.templateControl = [[UISegmentedControl alloc] initWithItems:@[@"模板 A", @"模板 B"]];
    self.templateControl.selectedSegmentIndex = 0;
    self.templateControl.backgroundColor = [UIColor colorWithRed:0.94 green:0.95 blue:1 alpha:1];
    self.templateControl.selectedSegmentTintColor = [UIColor colorWithRed:0.26 green:0.33 blue:1 alpha:1];
    [self.templateControl setTitleTextAttributes:@{NSForegroundColorAttributeName: UIColor.whiteColor, NSFontAttributeName: [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold]} forState:UIControlStateSelected];
    [self.templateControl setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:0.22 green:0.25 blue:0.38 alpha:1], NSFontAttributeName: [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold]} forState:UIControlStateNormal];
    [[self.templateControl.heightAnchor constraintEqualToConstant:38] setActive:YES];
    [container addArrangedSubview:self.templateControl];

    self.previewPDFButton = [self actionButtonWithTitle:@"预览 HTML 简历" background:[UIColor colorWithRed:0.26 green:0.33 blue:1 alpha:1] titleColor:UIColor.whiteColor];
    [self.previewPDFButton addTarget:self action:@selector(previewHTMLTapped) forControlEvents:UIControlEventTouchUpInside];
    [container addArrangedSubview:self.previewPDFButton];

    return page;
}

- (UIView *)pageWithTitle:(NSString *)title fields:(NSArray<UIView *> *)fields {
    UIView *page = [[UIView alloc] init];

    UIScrollView *innerScroll = [[UIScrollView alloc] init];
    innerScroll.translatesAutoresizingMaskIntoConstraints = NO;
    innerScroll.alwaysBounceVertical = YES;
    [page addSubview:innerScroll];

    [NSLayoutConstraint activateConstraints:@[
        [innerScroll.topAnchor constraintEqualToAnchor:page.topAnchor],
        [innerScroll.leadingAnchor constraintEqualToAnchor:page.leadingAnchor],
        [innerScroll.trailingAnchor constraintEqualToAnchor:page.trailingAnchor],
        [innerScroll.bottomAnchor constraintEqualToAnchor:page.bottomAnchor]
    ]];

    UIView *card = [[UIView alloc] init];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    card.backgroundColor = UIColor.whiteColor;
    card.layer.cornerRadius = 16;
    card.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.08].CGColor;
    card.layer.shadowOpacity = 1;
    card.layer.shadowOffset = CGSizeMake(0, 6);
    card.layer.shadowRadius = 16;
    [innerScroll addSubview:card];

    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 12;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:stack];

    UILabel *label = [[UILabel alloc] init];
    label.text = title;
    label.font = [UIFont boldSystemFontOfSize:22];
    label.textColor = [UIColor colorWithRed:0.1 green:0.13 blue:0.24 alpha:1];
    [stack addArrangedSubview:label];

    for (UIView *field in fields) {
        [stack addArrangedSubview:field];
    }

    [NSLayoutConstraint activateConstraints:@[
        [card.topAnchor constraintEqualToAnchor:innerScroll.contentLayoutGuide.topAnchor constant:16],
        [card.leadingAnchor constraintEqualToAnchor:innerScroll.frameLayoutGuide.leadingAnchor constant:16],
        [card.trailingAnchor constraintEqualToAnchor:innerScroll.frameLayoutGuide.trailingAnchor constant:-16],
        [card.bottomAnchor constraintEqualToAnchor:innerScroll.contentLayoutGuide.bottomAnchor constant:-16],

        [stack.topAnchor constraintEqualToAnchor:card.topAnchor constant:16],
        [stack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [stack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],
        [stack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-16]
    ]];

    return page;
}

- (nullable UIStackView *)findContainerStackInPage:(UIView *)page {
    for (UIView *subview in page.subviews) {
        if (![subview isKindOfClass:[UIScrollView class]]) {
            continue;
        }
        UIScrollView *innerScroll = (UIScrollView *)subview;
        for (UIView *card in innerScroll.subviews) {
            for (UIView *nested in card.subviews) {
                if ([nested isKindOfClass:[UIStackView class]]) {
                    return (UIStackView *)nested;
                }
            }
        }
    }
    return nil;
}

- (UITextField *)textField:(NSString *)key placeholder:(NSString *)placeholder {
    UITextField *field = [[UITextField alloc] init];
    field.placeholder = placeholder;
    field.borderStyle = UITextBorderStyleRoundedRect;
    field.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    field.translatesAutoresizingMaskIntoConstraints = NO;
    [[field.heightAnchor constraintEqualToConstant:42] setActive:YES];
    self.inputs[key] = field;
    return field;
}

- (UIView *)textView:(NSString *)key placeholder:(NSString *)placeholder {
    UIView *wrapper = [[UIView alloc] init];

    UITextView *textView = [[UITextView alloc] init];
    textView.font = [UIFont systemFontOfSize:15];
    textView.layer.cornerRadius = 12;
    textView.layer.borderColor = [UIColor colorWithRed:0.89 green:0.90 blue:0.96 alpha:1].CGColor;
    textView.layer.borderWidth = 1;
    textView.text = placeholder;
    textView.textColor = [UIColor colorWithRed:0.65 green:0.67 blue:0.74 alpha:1];
    textView.delegate = self;
    textView.accessibilityIdentifier = key;
    textView.translatesAutoresizingMaskIntoConstraints = NO;

    [wrapper addSubview:textView];
    [NSLayoutConstraint activateConstraints:@[
        [textView.topAnchor constraintEqualToAnchor:wrapper.topAnchor],
        [textView.leadingAnchor constraintEqualToAnchor:wrapper.leadingAnchor],
        [textView.trailingAnchor constraintEqualToAnchor:wrapper.trailingAnchor],
        [textView.bottomAnchor constraintEqualToAnchor:wrapper.bottomAnchor],
        [textView.heightAnchor constraintEqualToConstant:220]
    ]];

    self.inputs[key] = textView;
    return wrapper;
}

- (UIButton *)actionButtonWithTitle:(NSString *)title background:(UIColor *)bg titleColor:(UIColor *)fg {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:fg forState:UIControlStateNormal];
    button.backgroundColor = bg;
    button.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    button.layer.cornerRadius = 12;
    [[button.heightAnchor constraintEqualToConstant:48] setActive:YES];
    return button;
}

- (void)previewHTMLTapped {
    ResumeData *data = [self collectData];
    NSInteger selectedTemplate = self.templateControl ? self.templateControl.selectedSegmentIndex : 0;
    NSURL *htmlURL = [PDFResumeRenderer writeHTMLForResume:data templateIndex:selectedTemplate];
    if (!htmlURL) {
        [self showAlert:@"预览失败" message:@"HTML 生成失败，请稍后重试。"];
        return;
    }

    NSString *safeName = data.name.length > 0 ? data.name : @"Resume";
    NSString *pdfName = [NSString stringWithFormat:@"%@_Template%ld.pdf", safeName, (long)(selectedTemplate + 1)];
    ResumeHTMLPreviewController *previewVC = [[ResumeHTMLPreviewController alloc] initWithHTMLURL:htmlURL fileName:pdfName];
    [self.navigationController pushViewController:previewVC animated:YES];
}

- (ResumeData *)collectData {
    ResumeData *data = [[ResumeData alloc] init];
    data.name = [self textForKey:@"name"];
    data.targetRole = [self textForKey:@"targetRole"];
    data.phone = [self textForKey:@"phone"];
    data.email = [self textForKey:@"email"];
    data.city = [self textForKey:@"city"];
    data.portfolio = [self textForKey:@"portfolio"];
    data.summary = [self textForKey:@"summary"];
    data.education = [self linesForKey:@"education" separator:@"\n"];
    data.experiences = [self linesForKey:@"experiences" separator:@"\n\n"];
    data.skills = [self linesForKey:@"skills" separator:@","];
    data.projects = [self linesForKey:@"projects" separator:@"\n"];
    return data;
}

- (NSString *)textForKey:(NSString *)key {
    UIView *view = self.inputs[key];
    if ([view isKindOfClass:[UITextField class]]) {
        return ((UITextField *)view).text ?: @"";
    }

    if ([view isKindOfClass:[UITextView class]]) {
        UITextView *textView = (UITextView *)view;
        UIColor *placeholderColor = [UIColor colorWithRed:0.65 green:0.67 blue:0.74 alpha:1];
        if ([textView.textColor isEqual:placeholderColor]) {
            return @"";
        }
        return textView.text ?: @"";
    }

    return @"";
}

- (NSArray<NSString *> *)linesForKey:(NSString *)key separator:(NSString *)separator {
    NSString *raw = [self textForKey:key];
    NSArray<NSString *> *parts = [raw componentsSeparatedByString:separator];
    NSMutableArray<NSString *> *result = [NSMutableArray array];
    for (NSString *part in parts) {
        NSString *trim = [part stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trim.length > 0) {
            [result addObject:trim];
        }
    }
    return result;
}

- (void)showAlert:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
    UIColor *placeholderColor = [UIColor colorWithRed:0.65 green:0.67 blue:0.74 alpha:1];
    if ([textView.textColor isEqual:placeholderColor]) {
        textView.text = @"";
        textView.textColor = [UIColor colorWithRed:0.17 green:0.19 blue:0.22 alpha:1];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (textView.text.length == 0) {
        NSString *key = textView.accessibilityIdentifier;
        textView.text = self.placeholders[key] ?: @"";
        textView.textColor = [UIColor colorWithRed:0.65 green:0.67 blue:0.74 alpha:1];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView != self.pagesScrollView || scrollView.bounds.size.width <= 0) {
        return;
    }

    NSInteger page = (NSInteger)llround(scrollView.contentOffset.x / scrollView.bounds.size.width);
    self.pageControl.currentPage = MAX(0, MIN(page, self.pageControl.numberOfPages - 1));
}

@end
