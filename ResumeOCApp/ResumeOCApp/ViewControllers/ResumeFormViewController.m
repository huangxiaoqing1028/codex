#import "ResumeFormViewController.h"
#import "../Models/ResumeData.h"
#import "../Utilities/PDFResumeRenderer.h"

@interface ResumeFormViewController () <UITextFieldDelegate, UITextViewDelegate>
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *stack;
@property (nonatomic, strong) UIButton *exportButton;
@property (nonatomic, strong) UITextView *previewView;
@property (nonatomic, strong) NSMutableDictionary<NSString *, UIView *> *inputs;
@end

@implementation ResumeFormViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"简历生成器 Pro";
    self.view.backgroundColor = [UIColor colorWithRed:0.95 green:0.97 blue:1 alpha:1.0];
    self.inputs = [NSMutableDictionary dictionary];
    [self buildUI];
}

- (void)buildUI {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.scrollView];

    self.stack = [[UIStackView alloc] init];
    self.stack.axis = UILayoutConstraintAxisVertical;
    self.stack.spacing = 14;
    self.stack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:self.stack];

    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [self.stack.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor constant:16],
        [self.stack.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor constant:16],
        [self.stack.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor constant:-16],
        [self.stack.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor constant:-20],
        [self.stack.widthAnchor constraintEqualToAnchor:self.scrollView.widthAnchor constant:-32]
    ]];

    [self.stack addArrangedSubview:[self cardWithTitle:@"基本信息" fields:@[
        [self textField:@"name" placeholder:@"姓名"],
        [self textField:@"targetRole" placeholder:@"应聘岗位"],
        [self textField:@"phone" placeholder:@"手机号"],
        [self textField:@"email" placeholder:@"邮箱"],
        [self textField:@"city" placeholder:@"所在城市"],
        [self textField:@"portfolio" placeholder:@"作品集链接"]
    ]]];

    [self.stack addArrangedSubview:[self cardWithTitle:@"职业概述" fields:@[
        [self textView:@"summary" placeholder:@"一句话介绍你的优势、经验与价值主张"]
    ]]];

    [self.stack addArrangedSubview:[self cardWithTitle:@"教育背景" fields:@[
        [self textView:@"education" placeholder:@"每行一条，例如：2016-2020 XXX大学 本科"]
    ]]];

    [self.stack addArrangedSubview:[self cardWithTitle:@"工作经历" fields:@[
        [self textView:@"experiences" placeholder:@"每段空行分隔，描述成果时尽量量化"]
    ]]];

    [self.stack addArrangedSubview:[self cardWithTitle:@"技能与项目" fields:@[
        [self textField:@"skills" placeholder:@"核心技能，逗号分隔"],
        [self textView:@"projects" placeholder:@"每行一个项目亮点"]
    ]]];

    UIButton *previewBtn = [self actionButtonWithTitle:@"预览简历内容" background:[UIColor colorWithRed:0.90 green:0.93 blue:1 alpha:1] titleColor:[UIColor colorWithRed:0.2 green:0.24 blue:0.43 alpha:1]];
    [previewBtn addTarget:self action:@selector(previewTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.stack addArrangedSubview:previewBtn];

    self.exportButton = [self actionButtonWithTitle:@"生成 PDF 并调起打印" background:[UIColor colorWithRed:0.26 green:0.33 blue:1 alpha:1] titleColor:UIColor.whiteColor];
    [self.exportButton addTarget:self action:@selector(exportTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.stack addArrangedSubview:self.exportButton];

    self.previewView = [[UITextView alloc] init];
    self.previewView.editable = NO;
    self.previewView.backgroundColor = [UIColor colorWithRed:0.08 green:0.11 blue:0.20 alpha:1.0];
    self.previewView.textColor = [UIColor colorWithRed:0.88 green:0.92 blue:1 alpha:1.0];
    self.previewView.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
    self.previewView.layer.cornerRadius = 14;
    self.previewView.text = @"点击“预览简历内容”查看结构化内容。";
    self.previewView.translatesAutoresizingMaskIntoConstraints = NO;
    [[self.previewView.heightAnchor constraintEqualToConstant:220] setActive:YES];
    [self.stack addArrangedSubview:self.previewView];
}

- (UIView *)cardWithTitle:(NSString *)title fields:(NSArray<UIView *> *)fields {
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = UIColor.whiteColor;
    card.layer.cornerRadius = 16;
    card.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.08].CGColor;
    card.layer.shadowOpacity = 1;
    card.layer.shadowOffset = CGSizeMake(0, 6);
    card.layer.shadowRadius = 16;

    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 10;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:stack];

    UILabel *label = [[UILabel alloc] init];
    label.text = title;
    label.font = [UIFont boldSystemFontOfSize:18];
    [stack addArrangedSubview:label];

    for (UIView *view in fields) {
      [stack addArrangedSubview:view];
    }

    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:card.topAnchor constant:14],
        [stack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:14],
        [stack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-14],
        [stack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-14]
    ]];

    return card;
}

- (UITextField *)textField:(NSString *)key placeholder:(NSString *)placeholder {
    UITextField *field = [[UITextField alloc] init];
    field.placeholder = placeholder;
    field.borderStyle = UITextBorderStyleRoundedRect;
    [[field.heightAnchor constraintEqualToConstant:42] setActive:YES];
    field.delegate = self;
    self.inputs[key] = field;
    return field;
}

- (UIView *)textView:(NSString *)key placeholder:(NSString *)placeholder {
    UIView *wrapper = [[UIView alloc] init];
    wrapper.translatesAutoresizingMaskIntoConstraints = NO;

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
        [textView.heightAnchor constraintEqualToConstant:112]
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

- (void)previewTapped {
    ResumeData *data = [self collectData];
    NSDictionary *json = @{
        @"name": data.name,
        @"targetRole": data.targetRole,
        @"phone": data.phone,
        @"email": data.email,
        @"city": data.city,
        @"portfolio": data.portfolio,
        @"summary": data.summary,
        @"education": data.education,
        @"experiences": data.experiences,
        @"skills": data.skills,
        @"projects": data.projects
    };

    NSData *raw = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:nil];
    self.previewView.text = [[NSString alloc] initWithData:raw encoding:NSUTF8StringEncoding];
}

- (void)exportTapped {
    ResumeData *data = [self collectData];
    NSURL *fileURL = [PDFResumeRenderer renderPDFForResume:data];
    if (!fileURL) {
        [self showAlert:@"导出失败" message:@"PDF 生成失败，请稍后重试。"];
        return;
    }

    UIPrintInteractionController *printController = [UIPrintInteractionController sharedPrintController];
    if (!printController || ![UIPrintInteractionController canPrintURL:fileURL]) {
        [self showAlert:@"导出失败" message:@"当前设备不支持打印该文件。"];
        return;
    }

    UIPrintInfo *printInfo = [UIPrintInfo printInfo];
    printInfo.outputType = UIPrintInfoOutputGeneral;
    printInfo.jobName = @"Resume PDF";
    printController.printInfo = printInfo;
    printController.printingItem = fileURL;

    __weak typeof(self) weakSelf = self;
    [printController presentAnimated:YES completionHandler:^(UIPrintInteractionController * _Nonnull controller, BOOL completed, NSError * _Nullable error) {
        if (error) {
            [weakSelf showAlert:@"打印失败" message:error.localizedDescription ?: @"未知错误"];
        } else if (completed) {
            [weakSelf showAlert:@"完成" message:[NSString stringWithFormat:@"PDF 已生成：%@", fileURL.path]];
        }
    }];
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
        if ([textView.textColor isEqual:[UIColor colorWithRed:0.65 green:0.67 blue:0.74 alpha:1]]) {
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
    if ([textView.textColor isEqual:[UIColor colorWithRed:0.65 green:0.67 blue:0.74 alpha:1]]) {
        textView.text = @"";
        textView.textColor = [UIColor colorWithRed:0.17 green:0.19 blue:0.22 alpha:1];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (textView.text.length == 0) {
        NSString *key = textView.accessibilityIdentifier;
        NSDictionary *placeholders = @{
            @"summary": @"一句话介绍你的优势、经验与价值主张",
            @"education": @"每行一条，例如：2016-2020 XXX大学 本科",
            @"experiences": @"每段空行分隔，描述成果时尽量量化",
            @"projects": @"每行一个项目亮点"
        };
        textView.text = placeholders[key] ?: @"";
        textView.textColor = [UIColor colorWithRed:0.65 green:0.67 blue:0.74 alpha:1];
    }
}

@end
