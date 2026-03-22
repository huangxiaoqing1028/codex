#import "ViewController.h"
#import "NameGenerator.h"

@interface ViewController ()
@property (nonatomic, strong) CAGradientLayer *backgroundLayer;
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *meaningLabel;
@property (nonatomic, strong) UILabel *taglineLabel;
@property (nonatomic, strong) UISegmentedControl *styleControl;
@property (nonatomic, strong) UISlider *luckySlider;
@property (nonatomic, strong) UILabel *luckyValueLabel;
@property (nonatomic, strong) UIButton *generateButton;
@property (nonatomic, strong) NameGenerator *generator;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.generator = [NameGenerator new];
    [self setupViews];
    [self generateName];
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

    self.titleLabel = [self labelWithText:@"英文名生成器" font:[UIFont systemFontOfSize:30 weight:UIFontWeightBold]];
    self.nameLabel = [self labelWithText:@"Avery" font:[UIFont systemFontOfSize:46 weight:UIFontWeightHeavy]];
    self.nameLabel.adjustsFontSizeToFitWidth = YES;
    self.nameLabel.minimumScaleFactor = 0.6;
    self.meaningLabel = [self labelWithText:@"智慧且独立" font:[UIFont systemFontOfSize:19 weight:UIFontWeightSemibold]];
    self.taglineLabel = [self labelWithText:@"清新现代 · 幸运数字 7" font:[UIFont systemFontOfSize:15 weight:UIFontWeightRegular]];
    self.taglineLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.88];

    self.styleControl = [[UISegmentedControl alloc] initWithItems:@[@"中性", @"男生", @"女生"]];
    self.styleControl.translatesAutoresizingMaskIntoConstraints = NO;
    self.styleControl.selectedSegmentIndex = 0;
    self.styleControl.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.15];
    self.styleControl.selectedSegmentTintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.33];
    [self.styleControl setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateNormal];
    [self.styleControl addTarget:self action:@selector(generateName) forControlEvents:UIControlEventValueChanged];

    self.luckySlider = [[UISlider alloc] init];
    self.luckySlider.translatesAutoresizingMaskIntoConstraints = NO;
    self.luckySlider.minimumValue = 1;
    self.luckySlider.maximumValue = 99;
    self.luckySlider.value = 7;
    self.luckySlider.minimumTrackTintColor = [UIColor whiteColor];
    self.luckySlider.maximumTrackTintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3];
    [self.luckySlider addTarget:self action:@selector(updateLuckyLabel) forControlEvents:UIControlEventValueChanged];

    self.luckyValueLabel = [self labelWithText:@"幸运数字：7" font:[UIFont systemFontOfSize:14 weight:UIFontWeightMedium]];

    self.generateButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.generateButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.generateButton setTitle:@"生成我的英文名" forState:UIControlStateNormal];
    self.generateButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    [self.generateButton setTitleColor:[UIColor colorWithRed:0.29 green:0.08 blue:0.44 alpha:1] forState:UIControlStateNormal];
    self.generateButton.backgroundColor = [UIColor whiteColor];
    self.generateButton.layer.cornerRadius = 16;
    [self.generateButton addTarget:self action:@selector(generateName) forControlEvents:UIControlEventTouchUpInside];

    NSArray<UIView *> *items = @[self.titleLabel, self.nameLabel, self.meaningLabel, self.taglineLabel,
                                 self.styleControl, self.luckyValueLabel, self.luckySlider, self.generateButton];
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

        [self.nameLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:12],
        [self.nameLabel.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
        [self.nameLabel.trailingAnchor constraintEqualToAnchor:self.titleLabel.trailingAnchor],

        [self.meaningLabel.topAnchor constraintEqualToAnchor:self.nameLabel.bottomAnchor constant:6],
        [self.meaningLabel.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
        [self.meaningLabel.trailingAnchor constraintEqualToAnchor:self.titleLabel.trailingAnchor],

        [self.taglineLabel.topAnchor constraintEqualToAnchor:self.meaningLabel.bottomAnchor constant:6],
        [self.taglineLabel.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
        [self.taglineLabel.trailingAnchor constraintEqualToAnchor:self.titleLabel.trailingAnchor],

        [self.styleControl.topAnchor constraintEqualToAnchor:self.taglineLabel.bottomAnchor constant:22],
        [self.styleControl.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
        [self.styleControl.trailingAnchor constraintEqualToAnchor:self.titleLabel.trailingAnchor],

        [self.luckyValueLabel.topAnchor constraintEqualToAnchor:self.styleControl.bottomAnchor constant:16],
        [self.luckyValueLabel.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
        [self.luckyValueLabel.trailingAnchor constraintEqualToAnchor:self.titleLabel.trailingAnchor],

        [self.luckySlider.topAnchor constraintEqualToAnchor:self.luckyValueLabel.bottomAnchor constant:10],
        [self.luckySlider.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
        [self.luckySlider.trailingAnchor constraintEqualToAnchor:self.titleLabel.trailingAnchor],

        [self.generateButton.topAnchor constraintEqualToAnchor:self.luckySlider.bottomAnchor constant:24],
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

- (void)generateName {
    [self updateLuckyLabel];
    ENGNameStyle style = (ENGNameStyle)self.styleControl.selectedSegmentIndex;
    ENGNameResult *result = [self.generator generateNameWithStyle:style luckyNumber:(NSInteger)round(self.luckySlider.value)];

    self.nameLabel.text = result.name;
    self.meaningLabel.text = result.meaning;
    self.taglineLabel.text = result.tagline;

    [UIView transitionWithView:self.cardView
                      duration:0.25
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{}
                    completion:nil];
}

@end
