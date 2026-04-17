#import "RSHomeViewController.h"
#import "RSResume.h"
#import "RSResumeStore.h"
#import "RSTemplatePreviewViewController.h"
#import "RSPDFExportService.h"
#import "RSTheme.h"

@interface RSHomeViewController () <UITextFieldDelegate, UITextViewDelegate>
@property (nonatomic, strong) RSResume *resume;
@property (nonatomic, strong) UIStackView *stack;
@property (nonatomic, strong) NSMutableDictionary<NSString *, UIView *> *fields;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UILabel *progressLabel;
@end

@implementation RSHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [RSTheme bgPrimary];
    self.title = @"Resume Pro Studio";
    self.resume = [RSResume emptyResume];
    self.fields = [NSMutableDictionary dictionary];

    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:scrollView];

    self.stack = [[UIStackView alloc] init];
    self.stack.axis = UILayoutConstraintAxisVertical;
    self.stack.spacing = 14;
    self.stack.translatesAutoresizingMaskIntoConstraints = NO;
    [scrollView addSubview:self.stack];

    [NSLayoutConstraint activateConstraints:@[
        [scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [self.stack.topAnchor constraintEqualToAnchor:scrollView.topAnchor constant:16],
        [self.stack.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.stack.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.stack.bottomAnchor constraintEqualToAnchor:scrollView.bottomAnchor constant:-24],
    ]];

    [self buildHero];
    [self addTextField:@"姓名" key:@"fullName" keyboard:UIKeyboardTypeDefault];
    [self addTextField:@"电话" key:@"phone" keyboard:UIKeyboardTypePhonePad];
    [self addTextField:@"邮箱" key:@"email" keyboard:UIKeyboardTypeEmailAddress];
    [self addTextField:@"目标岗位" key:@"jobTitle" keyboard:UIKeyboardTypeDefault];
    [self addTextView:@"个人简介" key:@"summary"];
    [self addTextView:@"教育经历" key:@"education"];
    [self addTextView:@"工作经历" key:@"experience"];
    [self addTextView:@"技能证书" key:@"skills"];

    [self addActionButton:@"预览与模板切换" action:@selector(onPreview) primary:NO];
    [self addActionButton:@"一键导出 PDF" action:@selector(onExportPDF) primary:YES];

    UIBarButtonItem *save = [[UIBarButtonItem alloc] initWithTitle:@"保存" style:UIBarButtonItemStyleDone target:self action:@selector(onSave)];
    self.navigationItem.rightBarButtonItem = save;
}

- (void)buildHero {
    UIView *card = [self cardContainer];

    UILabel *title = [[UILabel alloc] init];
    title.text = @"打造高端商务简历";
    title.textColor = [RSTheme textPrimary];
    title.font = [RSTheme titleFont];
    title.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *subtitle = [[UILabel alloc] init];
    subtitle.text = @"自动排版 · 多模板 · 专业 PDF 导出";
    subtitle.textColor = [RSTheme textSecondary];
    subtitle.font = [RSTheme bodyFont];
    subtitle.translatesAutoresizingMaskIntoConstraints = NO;

    self.progressLabel = [[UILabel alloc] init];
    self.progressLabel.text = @"简历完整度 0%";
    self.progressLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    self.progressLabel.textColor = [RSTheme accentGold];
    self.progressLabel.translatesAutoresizingMaskIntoConstraints = NO;

    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progressView.progressTintColor = [RSTheme accentGold];
    self.progressView.trackTintColor = [UIColor colorWithWhite:1 alpha:0.15];
    self.progressView.translatesAutoresizingMaskIntoConstraints = NO;

    [card addSubview:title];
    [card addSubview:subtitle];
    [card addSubview:self.progressLabel];
    [card addSubview:self.progressView];

    [NSLayoutConstraint activateConstraints:@[
        [title.topAnchor constraintEqualToAnchor:card.topAnchor constant:16],
        [title.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [title.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],

        [subtitle.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:8],
        [subtitle.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [subtitle.trailingAnchor constraintEqualToAnchor:title.trailingAnchor],

        [self.progressLabel.topAnchor constraintEqualToAnchor:subtitle.bottomAnchor constant:16],
        [self.progressLabel.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],

        [self.progressView.topAnchor constraintEqualToAnchor:self.progressLabel.bottomAnchor constant:8],
        [self.progressView.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [self.progressView.trailingAnchor constraintEqualToAnchor:title.trailingAnchor],
        [self.progressView.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-16],
    ]];

    [self.stack addArrangedSubview:card];
}

- (UIView *)cardContainer {
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [RSTheme cardBackground];
    card.layer.cornerRadius = 16;
    card.layer.borderColor = [RSTheme border].CGColor;
    card.layer.borderWidth = 1;
    card.translatesAutoresizingMaskIntoConstraints = NO;
    return card;
}

- (void)addTextField:(NSString *)placeholder key:(NSString *)key keyboard:(UIKeyboardType)keyboard {
    UIView *card = [self cardContainer];
    UITextField *tf = [[UITextField alloc] init];
    tf.placeholder = placeholder;
    tf.borderStyle = UITextBorderStyleNone;
    tf.textColor = [RSTheme textPrimary];
    tf.tintColor = [RSTheme accentGold];
    tf.keyboardType = keyboard;
    tf.delegate = self;
    tf.accessibilityIdentifier = key;
    tf.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *caption = [[UILabel alloc] init];
    caption.text = placeholder;
    caption.textColor = [RSTheme textSecondary];
    caption.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    caption.translatesAutoresizingMaskIntoConstraints = NO;

    [card addSubview:caption];
    [card addSubview:tf];
    [NSLayoutConstraint activateConstraints:@[
        [caption.topAnchor constraintEqualToAnchor:card.topAnchor constant:10],
        [caption.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:14],
        [caption.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-14],

        [tf.topAnchor constraintEqualToAnchor:caption.bottomAnchor constant:6],
        [tf.leadingAnchor constraintEqualToAnchor:caption.leadingAnchor],
        [tf.trailingAnchor constraintEqualToAnchor:caption.trailingAnchor],
        [tf.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-10],
        [tf.heightAnchor constraintEqualToConstant:24],
    ]];

    [self.stack addArrangedSubview:card];
    self.fields[key] = tf;
}

- (void)addTextView:(NSString *)title key:(NSString *)key {
    UIView *card = [self cardContainer];
    UILabel *caption = [[UILabel alloc] init];
    caption.text = title;
    caption.textColor = [RSTheme textSecondary];
    caption.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    caption.translatesAutoresizingMaskIntoConstraints = NO;

    UITextView *tv = [[UITextView alloc] init];
    tv.backgroundColor = [RSTheme bgSecondary];
    tv.textColor = [RSTheme textPrimary];
    tv.layer.cornerRadius = 10;
    tv.font = [RSTheme bodyFont];
    tv.delegate = self;
    tv.accessibilityIdentifier = key;
    tv.translatesAutoresizingMaskIntoConstraints = NO;

    [card addSubview:caption];
    [card addSubview:tv];
    [NSLayoutConstraint activateConstraints:@[
        [caption.topAnchor constraintEqualToAnchor:card.topAnchor constant:10],
        [caption.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:14],
        [caption.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-14],

        [tv.topAnchor constraintEqualToAnchor:caption.bottomAnchor constant:8],
        [tv.leadingAnchor constraintEqualToAnchor:caption.leadingAnchor],
        [tv.trailingAnchor constraintEqualToAnchor:caption.trailingAnchor],
        [tv.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-10],
        [tv.heightAnchor constraintEqualToConstant:100],
    ]];

    [self.stack addArrangedSubview:card];
    self.fields[key] = tv;
}

- (void)addActionButton:(NSString *)title action:(SEL)action primary:(BOOL)primary {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn setTitle:title forState:UIControlStateNormal];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    btn.layer.cornerRadius = 14;
    btn.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];

    if (primary) {
        btn.backgroundColor = [RSTheme accentGold];
        [btn setTitleColor:[RSTheme bgPrimary] forState:UIControlStateNormal];
    } else {
        btn.backgroundColor = [RSTheme cardBackground];
        [btn setTitleColor:[RSTheme textPrimary] forState:UIControlStateNormal];
        btn.layer.borderWidth = 1;
        btn.layer.borderColor = [RSTheme border].CGColor;
    }

    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [btn.heightAnchor constraintEqualToConstant:52].active = YES;
    [self.stack addArrangedSubview:btn];
}

- (void)onSave {
    [self syncModel];
    [[RSResumeStore shared] saveResume:self.resume];
    [self toast:@"草稿已保存"];
}

- (void)onPreview {
    [self syncModel];
    RSTemplatePreviewViewController *vc = [[RSTemplatePreviewViewController alloc] initWithResume:self.resume];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onExportPDF {
    [self syncModel];
    NSError *error = nil;
    NSURL *fileURL = [[[RSPDFExportService alloc] init] exportResume:self.resume error:&error];
    if (error || !fileURL) {
        [self toast:@"导出失败，请稍后重试"];
        return;
    }
    UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:@[fileURL] applicationActivities:nil];
    [self presentViewController:activity animated:YES completion:nil];
}

- (void)syncModel {
    self.resume.fullName = ((UITextField *)self.fields[@"fullName"]).text ?: @"";
    self.resume.phone = ((UITextField *)self.fields[@"phone"]).text ?: @"";
    self.resume.email = ((UITextField *)self.fields[@"email"]).text ?: @"";
    self.resume.jobTitle = ((UITextField *)self.fields[@"jobTitle"]).text ?: @"";
    self.resume.summary = ((UITextView *)self.fields[@"summary"]).text ?: @"";
    self.resume.education = ((UITextView *)self.fields[@"education"]).text ?: @"";
    self.resume.experience = ((UITextView *)self.fields[@"experience"]).text ?: @"";
    self.resume.skills = ((UITextView *)self.fields[@"skills"]).text ?: @"";
    [self refreshProgress];
}

- (void)refreshProgress {
    NSArray<NSString *> *values = @[
        self.resume.fullName, self.resume.phone, self.resume.email, self.resume.jobTitle,
        self.resume.summary, self.resume.education, self.resume.experience, self.resume.skills
    ];
    NSInteger filled = 0;
    for (NSString *v in values) {
        if (v.length > 0) { filled += 1; }
    }
    CGFloat progress = (CGFloat)filled / (CGFloat)values.count;
    self.progressView.progress = progress;
    self.progressLabel.text = [NSString stringWithFormat:@"简历完整度 %.0f%%", progress * 100];
}

- (void)textFieldDidEndEditing:(UITextField *)textField { [self syncModel]; }
- (void)textViewDidEndEditing:(UITextView *)textView { [self syncModel]; }

- (void)toast:(NSString *)text {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:text preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alert animated:YES completion:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [alert dismissViewControllerAnimated:YES completion:nil];
    });
}

@end
