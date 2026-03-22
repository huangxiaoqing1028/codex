#import "ResultViewController.h"
#import "NameGenerator.h"

@interface ResultViewController ()
@property (nonatomic, strong) ENGNameResult *result;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *meaningLabel;
@property (nonatomic, strong) UILabel *taglineLabel;
@end

@implementation ResultViewController

- (instancetype)initWithResult:(ENGNameResult *)result {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _result = result;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"生成结果";
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    UIView *card = [[UIView alloc] init];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    card.backgroundColor = [UIColor colorWithRed:0.96 green:0.95 blue:1 alpha:1];
    card.layer.cornerRadius = 22;
    card.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.2].CGColor;
    card.layer.shadowOffset = CGSizeMake(0, 10);
    card.layer.shadowOpacity = 0.18;
    card.layer.shadowRadius = 18;
    [self.view addSubview:card];

    self.nameLabel = [self buildLabelWithFont:[UIFont systemFontOfSize:42 weight:UIFontWeightHeavy] color:[UIColor colorWithRed:0.18 green:0.12 blue:0.35 alpha:1]];
    self.nameLabel.textAlignment = NSTextAlignmentCenter;
    self.nameLabel.adjustsFontSizeToFitWidth = YES;
    self.nameLabel.minimumScaleFactor = 0.65;

    self.meaningLabel = [self buildLabelWithFont:[UIFont systemFontOfSize:20 weight:UIFontWeightSemibold] color:[UIColor colorWithRed:0.24 green:0.20 blue:0.40 alpha:1]];
    self.meaningLabel.textAlignment = NSTextAlignmentCenter;

    self.taglineLabel = [self buildLabelWithFont:[UIFont systemFontOfSize:16 weight:UIFontWeightRegular] color:[UIColor colorWithRed:0.40 green:0.37 blue:0.55 alpha:1]];
    self.taglineLabel.textAlignment = NSTextAlignmentCenter;

    UIButton *copyButton = [UIButton buttonWithType:UIButtonTypeSystem];
    copyButton.translatesAutoresizingMaskIntoConstraints = NO;
    [copyButton setTitle:@"复制结果" forState:UIControlStateNormal];
    copyButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    [copyButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    copyButton.backgroundColor = [UIColor colorWithRed:0.30 green:0.14 blue:0.66 alpha:1];
    copyButton.layer.cornerRadius = 14;
    [copyButton addTarget:self action:@selector(copyResult) forControlEvents:UIControlEventTouchUpInside];

    [card addSubview:self.nameLabel];
    [card addSubview:self.meaningLabel];
    [card addSubview:self.taglineLabel];
    [card addSubview:copyButton];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [card.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:18],
        [card.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-18],
        [card.centerYAnchor constraintEqualToAnchor:safe.centerYAnchor],

        [self.nameLabel.topAnchor constraintEqualToAnchor:card.topAnchor constant:36],
        [self.nameLabel.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
        [self.nameLabel.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],

        [self.meaningLabel.topAnchor constraintEqualToAnchor:self.nameLabel.bottomAnchor constant:16],
        [self.meaningLabel.leadingAnchor constraintEqualToAnchor:self.nameLabel.leadingAnchor],
        [self.meaningLabel.trailingAnchor constraintEqualToAnchor:self.nameLabel.trailingAnchor],

        [self.taglineLabel.topAnchor constraintEqualToAnchor:self.meaningLabel.bottomAnchor constant:12],
        [self.taglineLabel.leadingAnchor constraintEqualToAnchor:self.nameLabel.leadingAnchor],
        [self.taglineLabel.trailingAnchor constraintEqualToAnchor:self.nameLabel.trailingAnchor],

        [copyButton.topAnchor constraintEqualToAnchor:self.taglineLabel.bottomAnchor constant:30],
        [copyButton.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],
        [copyButton.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],
        [copyButton.heightAnchor constraintEqualToConstant:50],
        [copyButton.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-24]
    ]];

    [self refreshContent];
}

- (UILabel *)buildLabelWithFont:(UIFont *)font color:(UIColor *)color {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.font = font;
    label.textColor = color;
    label.numberOfLines = 0;
    return label;
}

- (void)refreshContent {
    self.nameLabel.text = self.result.name;
    self.meaningLabel.text = self.result.meaning;
    self.taglineLabel.text = self.result.tagline;
}

- (void)copyResult {
    NSString *content = [NSString stringWithFormat:@"英文名：%@\n寓意：%@\n标签：%@", self.result.name ?: @"", self.result.meaning ?: @"", self.result.tagline ?: @""];
    [UIPasteboard generalPasteboard].string = content;

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"已复制" message:@"结果已复制到剪贴板" preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alert animated:YES completion:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [alert dismissViewControllerAnimated:YES completion:nil];
    });
}

@end
