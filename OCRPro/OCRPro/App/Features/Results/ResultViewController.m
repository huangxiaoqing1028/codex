#import "ResultViewController.h"

@interface ResultViewController ()
@property (nonatomic, copy) NSString *recognizedText;
@property (nonatomic, strong) UITextView *textView;
@end

@implementation ResultViewController

- (instancetype)initWithText:(NSString *)text {
    self = [super init];
    if (self) {
        _recognizedText = text;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"识别结果";
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    self.textView = [[UITextView alloc] init];
    self.textView.translatesAutoresizingMaskIntoConstraints = NO;
    self.textView.text = self.recognizedText.length > 0 ? self.recognizedText : @"未识别到文字，请尝试更清晰的图片。";
    self.textView.editable = NO;
    self.textView.font = [UIFont systemFontOfSize:17 weight:UIFontWeightRegular];
    self.textView.backgroundColor = [UIColor secondarySystemBackgroundColor];
    self.textView.layer.cornerRadius = 16;
    self.textView.textContainerInset = UIEdgeInsetsMake(18, 16, 18, 16);

    UIBarButtonItem *copyButton = [[UIBarButtonItem alloc] initWithTitle:@"复制" style:UIBarButtonItemStylePlain target:self action:@selector(copyText)];
    self.navigationItem.rightBarButtonItem = copyButton;

    [self.view addSubview:self.textView];
    [NSLayoutConstraint activateConstraints:@[
        [self.textView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:16],
        [self.textView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.textView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.textView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-16]
    ]];
}

- (void)copyText {
    [UIPasteboard generalPasteboard].string = self.textView.text;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"已复制" message:@"识别文本已复制到剪贴板。" preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alert animated:YES completion:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.9 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [alert dismissViewControllerAnimated:YES completion:nil];
    });
}

@end
