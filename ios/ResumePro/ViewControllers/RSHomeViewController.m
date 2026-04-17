#import "RSHomeViewController.h"
#import "RSResume.h"
#import "RSResumeStore.h"
#import "RSTemplatePreviewViewController.h"
#import "RSPDFExportService.h"

@interface RSHomeViewController () <UITextFieldDelegate, UITextViewDelegate>
@property (nonatomic, strong) RSResume *resume;
@property (nonatomic, strong) UIStackView *stack;
@property (nonatomic, strong) NSMutableDictionary<NSString *, UIView *> *fields;
@end

@implementation RSHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.title = @"高端简历制作";
    self.resume = [RSResume emptyResume];
    self.fields = [NSMutableDictionary dictionary];

    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:scrollView];

    self.stack = [[UIStackView alloc] init];
    self.stack.axis = UILayoutConstraintAxisVertical;
    self.stack.spacing = 12;
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
        [self.stack.bottomAnchor constraintEqualToAnchor:scrollView.bottomAnchor constant:-20],
    ]];

    [self addTextField:@"姓名" key:@"fullName"];
    [self addTextField:@"电话" key:@"phone"];
    [self addTextField:@"邮箱" key:@"email"];
    [self addTextField:@"目标岗位" key:@"jobTitle"];
    [self addTextView:@"个人简介" key:@"summary"];
    [self addTextView:@"教育经历" key:@"education"];
    [self addTextView:@"工作经历" key:@"experience"];
    [self addTextView:@"技能" key:@"skills"];

    [self addButton:@"预览与模板切换" action:@selector(onPreview)];
    [self addButton:@"一键导出 PDF" action:@selector(onExportPDF)];

    UIBarButtonItem *save = [[UIBarButtonItem alloc] initWithTitle:@"保存" style:UIBarButtonItemStyleDone target:self action:@selector(onSave)];
    self.navigationItem.rightBarButtonItem = save;
}

- (void)addTextField:(NSString *)placeholder key:(NSString *)key {
    UITextField *tf = [[UITextField alloc] init];
    tf.placeholder = placeholder;
    tf.borderStyle = UITextBorderStyleRoundedRect;
    tf.delegate = self;
    tf.accessibilityIdentifier = key;
    [tf.heightAnchor constraintEqualToConstant:44].active = YES;
    [self.stack addArrangedSubview:tf];
    self.fields[key] = tf;
}

- (void)addTextView:(NSString *)title key:(NSString *)key {
    UILabel *label = [[UILabel alloc] init];
    label.text = title;
    label.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    [self.stack addArrangedSubview:label];

    UITextView *tv = [[UITextView alloc] init];
    tv.layer.borderColor = [UIColor systemGray4Color].CGColor;
    tv.layer.borderWidth = 1;
    tv.layer.cornerRadius = 10;
    tv.delegate = self;
    tv.accessibilityIdentifier = key;
    tv.font = [UIFont systemFontOfSize:14];
    [tv.heightAnchor constraintEqualToConstant:96].active = YES;
    [self.stack addArrangedSubview:tv];
    self.fields[key] = tv;
}

- (void)addButton:(NSString *)title action:(SEL)action {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn setTitle:title forState:UIControlStateNormal];
    btn.backgroundColor = [UIColor colorWithRed:0.07 green:0.09 blue:0.12 alpha:1.0];
    [btn setTitleColor:[UIColor colorWithRed:0.78 green:0.64 blue:0.42 alpha:1.0] forState:UIControlStateNormal];
    btn.layer.cornerRadius = 12;
    btn.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [btn.heightAnchor constraintEqualToConstant:50].active = YES;
    [self.stack addArrangedSubview:btn];
}

- (void)onSave {
    [self syncModel];
    [[RSResumeStore shared] saveResume:self.resume];
    [self toast:@"已保存草稿"];
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
        [self toast:@"导出失败"];
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
}

- (void)toast:(NSString *)text {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:text preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alert animated:YES completion:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [alert dismissViewControllerAnimated:YES completion:nil];
    });
}

@end
