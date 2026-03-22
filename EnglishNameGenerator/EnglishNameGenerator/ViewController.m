#import "ViewController.h"
#import "NameGenerator.h"
#import "ResultViewController.h"

@interface ViewController ()
@property (nonatomic, strong) CAGradientLayer *backgroundLayer;
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UISegmentedControl *styleControl;
@property (nonatomic, strong) UISlider *luckySlider;
@property (nonatomic, strong) UILabel *luckyValueLabel;
@property (nonatomic, strong) UILabel *poolHintLabel;
@property (nonatomic, strong) UIButton *generateButton;
@property (nonatomic, strong) NameGenerator *generator;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"英文名生成器";
    self.generator = [NameGenerator new];
    [self setupViews];
    [self updateLuckyLabel];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.backgroundLayer.frame = self.view.bounds;
}

- (void)setupViews {
    self.view.backgroundColor = [UIColor blackColor];

    self.backgroundLayer = [CAGradientLayer layer];
    self.backgroundLayer.colors = @[(id)[UIColor colorWithRed:0.12 green:0.10 blue:0.28 alpha:1].CGColor,
                                    (id)[UIColor colorWithRed:0.30 green:0.10 blue:0.48 alpha:1].CGColor,
                                    (id)[UIColor colorWithRed:0.86 green:0.35 blue:0.65 alpha:1].CGColor];
    self.backgroundLayer.startPoint = CGPointMake(0.0, 0.0);
    self.backgroundLayer.endPoint = CGPointMake(1.0, 1.0);
    [self.view.layer addSublayer:self.backgroundLayer];

    UIView *blur = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark]];
    blur.frame = self.view.bounds;
    blur.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:blur];

    self.cardView = [[UIView alloc] init];
    self.cardView.translatesAutoresizingMaskIntoConstraints = NO;
    self.cardView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.14];
    self.cardView.layer.cornerRadius = 24;
    self.cardView.layer.borderWidth = 1;
    self.cardView.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.25].CGColor;
    self.cardView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.cardView.layer.shadowOpacity = 0.28;
    self.cardView.layer.shadowOffset = CGSizeMake(0, 16);
    self.cardView.layer.shadowRadius = 24;
    [self.view addSubview:self.cardView];

    self.titleLabel = [self labelWithText:@"定制你的英文名" font:[UIFont systemFontOfSize:32 weight:UIFontWeightBold]];
    self.subtitleLabel = [self labelWithText:@"词库已扩展到每种风格 1000 个候选，点击后在下一页展示并支持复制" font:[UIFont systemFontOfSize:16 weight:UIFontWeightMedium]];
    self.subtitleLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.9];

    self.styleControl = [[UISegmentedControl alloc] initWithItems:@[@"中性", @"男生", @"女生"]];
    self.styleControl.translatesAutoresizingMaskIntoConstraints = NO;
    self.styleControl.selectedSegmentIndex = 0;
    self.styleControl.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.15];
    self.styleControl.selectedSegmentTintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.33];
    [self.styleControl setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateNormal];

    self.luckySlider = [[UISlider alloc] init];
    self.luckySlider.translatesAutoresizingMaskIntoConstraints = NO;
    self.luckySlider.minimumValue = 1;
    self.luckySlider.maximumValue = 99;
    self.luckySlider.value = 7;
    self.luckySlider.minimumTrackTintColor = [UIColor whiteColor];
    self.luckySlider.maximumTrackTintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3];
    [self.luckySlider addTarget:self action:@selector(updateLuckyLabel) forControlEvents:UIControlEventValueChanged];

    self.luckyValueLabel = [self labelWithText:@"幸运数字：7" font:[UIFont systemFontOfSize:15 weight:UIFontWeightSemibold]];
    self.poolHintLabel = [self labelWithText:@"每种风格词库：1000" font:[UIFont systemFontOfSize:14 weight:UIFontWeightRegular]];
    self.poolHintLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.85];

    self.generateButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.generateButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.generateButton setTitle:@"生成并查看下一页结果" forState:UIControlStateNormal];
    self.generateButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    [self.generateButton setTitleColor:[UIColor colorWithRed:0.29 green:0.08 blue:0.44 alpha:1] forState:UIControlStateNormal];
    self.generateButton.backgroundColor = [UIColor whiteColor];
    self.generateButton.layer.cornerRadius = 16;
    [self.generateButton addTarget:self action:@selector(generateNameAndShowResult) forControlEvents:UIControlEventTouchUpInside];

    NSArray<UIView *> *items = @[self.titleLabel, self.subtitleLabel, self.styleControl, self.luckyValueLabel,
                                 self.luckySlider, self.poolHintLabel, self.generateButton];
    for (UIView *item in items) {
        [self.cardView addSubview:item];
    }

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.cardView.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:18],
        [self.cardView.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-18],
        [self.cardView.centerYAnchor constraintEqualToAnchor:safe.centerYAnchor],

        [self.titleLabel.topAnchor constraintEqualToAnchor:self.cardView.topAnchor constant:28],
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:20],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-20],

        [self.subtitleLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:12],
        [self.subtitleLabel.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
        [self.subtitleLabel.trailingAnchor constraintEqualToAnchor:self.titleLabel.trailingAnchor],

        [self.styleControl.topAnchor constraintEqualToAnchor:self.subtitleLabel.bottomAnchor constant:24],
        [self.styleControl.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
        [self.styleControl.trailingAnchor constraintEqualToAnchor:self.titleLabel.trailingAnchor],

        [self.luckyValueLabel.topAnchor constraintEqualToAnchor:self.styleControl.bottomAnchor constant:18],
        [self.luckyValueLabel.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
        [self.luckyValueLabel.trailingAnchor constraintEqualToAnchor:self.titleLabel.trailingAnchor],

        [self.luckySlider.topAnchor constraintEqualToAnchor:self.luckyValueLabel.bottomAnchor constant:10],
        [self.luckySlider.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
        [self.luckySlider.trailingAnchor constraintEqualToAnchor:self.titleLabel.trailingAnchor],

        [self.poolHintLabel.topAnchor constraintEqualToAnchor:self.luckySlider.bottomAnchor constant:12],
        [self.poolHintLabel.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
        [self.poolHintLabel.trailingAnchor constraintEqualToAnchor:self.titleLabel.trailingAnchor],

        [self.generateButton.topAnchor constraintEqualToAnchor:self.poolHintLabel.bottomAnchor constant:24],
        [self.generateButton.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
        [self.generateButton.trailingAnchor constraintEqualToAnchor:self.titleLabel.trailingAnchor],
        [self.generateButton.heightAnchor constraintEqualToConstant:52],
        [self.generateButton.bottomAnchor constraintEqualToAnchor:self.cardView.bottomAnchor constant:-24]
    ]];
}

- (UILabel *)labelWithText:(NSString *)text font:(UIFont *)font {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = text;
    label.font = font;
    label.textColor = [UIColor whiteColor];
    label.numberOfLines = 0;
    return label;
}

- (void)updateLuckyLabel {
    NSInteger luckyNumber = (NSInteger)round(self.luckySlider.value);
    self.luckyValueLabel.text = [NSString stringWithFormat:@"幸运数字：%ld", (long)luckyNumber];
}

- (void)generateNameAndShowResult {
    [self updateLuckyLabel];
    ENGNameStyle style = (ENGNameStyle)self.styleControl.selectedSegmentIndex;
    ENGNameResult *result = [self.generator generateNameWithStyle:style luckyNumber:(NSInteger)round(self.luckySlider.value)];

    ResultViewController *resultVC = [[ResultViewController alloc] initWithResult:result];
    [self.navigationController pushViewController:resultVC animated:YES];
}

@end
