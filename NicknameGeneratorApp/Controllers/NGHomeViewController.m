#import "NGHomeViewController.h"
#import "NGNicknameGenerator.h"
#import "NGStyleChipButton.h"
#import "NGDisplayViewController.h"
#import <StoreKit/StoreKit.h>

@interface NGHomeViewController ()
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *nicknameLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIButton *generateButton;
@property (nonatomic, strong) UISwitch *numberSwitch;
@property (nonatomic, strong) UILabel *numberSwitchLabel;
@property (nonatomic, strong) UIView *feedAdContainerView;
@property (nonatomic, strong) NSArray<NGStyleChipButton *> *styleButtons;
@property (nonatomic, copy) NSString *currentStyle;
@property (nonatomic, strong) NGNicknameGenerator *generator;
@property (nonatomic, assign) NSUInteger generationCount;
@end

@implementation NGHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.currentStyle = @"唯美";
    self.generator = [NGNicknameGenerator shared];
    self.generationCount = [[NSUserDefaults standardUserDefaults] integerForKey:@"ng_generation_count"];

    [self configureBackground];
    [self configureUI];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSettingsChanged) name:NGNicknameSettingDidChangeNotification object:nil];
    [self handleSettingsChanged];
    [self restoreLastNicknamePreview];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.gradientLayer.frame = self.view.bounds;
}

- (void)handleSettingsChanged {
    self.numberSwitch.on = self.generator.defaultIncludeNumber;
}

- (void)configureBackground {
    self.view.backgroundColor = [UIColor blackColor];
    self.gradientLayer = [CAGradientLayer layer];
    self.gradientLayer.colors = @[
        (id)[UIColor colorWithRed:0.10 green:0.12 blue:0.24 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.20 green:0.13 blue:0.35 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.06 green:0.07 blue:0.17 alpha:1.0].CGColor
    ];
    self.gradientLayer.startPoint = CGPointMake(0, 0);
    self.gradientLayer.endPoint = CGPointMake(1, 1);
    [self.view.layer addSublayer:self.gradientLayer];
}

- (void)configureUI {
    self.cardView = [[UIView alloc] init];
    self.cardView.translatesAutoresizingMaskIntoConstraints = NO;
    self.cardView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.10];
    self.cardView.layer.cornerRadius = 24;
    self.cardView.layer.borderWidth = 1;
    self.cardView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.2].CGColor;
    [self.view addSubview:self.cardView];

    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark];
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
    blurView.translatesAutoresizingMaskIntoConstraints = NO;
    blurView.layer.cornerRadius = 24;
    blurView.clipsToBounds = YES;
    [self.cardView addSubview:blurView];

    self.titleLabel = [self makeLabel:@"网名生成器" font:[UIFont systemFontOfSize:30 weight:UIFontWeightHeavy] alpha:1.0];
    self.subtitleLabel = [self makeLabel:[NSString stringWithFormat:@"词库 %lu+，点击生成即可出结果", (unsigned long)self.generator.libraryCount] font:[UIFont systemFontOfSize:14 weight:UIFontWeightRegular] alpha:0.85];
    self.nicknameLabel = [self makeLabel:@"点击按钮开始" font:[UIFont monospacedSystemFontOfSize:34 weight:UIFontWeightBold] alpha:1.0];
    self.nicknameLabel.numberOfLines = 0;
    self.nicknameLabel.textAlignment = NSTextAlignmentCenter;

    [self.cardView addSubview:self.titleLabel];
    [self.cardView addSubview:self.subtitleLabel];
    [self.cardView addSubview:self.nicknameLabel];

    NGStyleChipButton *pretty = [[NGStyleChipButton alloc] initWithTitle:@"唯美"];
    NGStyleChipButton *ancient = [[NGStyleChipButton alloc] initWithTitle:@"古风"];
    NGStyleChipButton *cyber = [[NGStyleChipButton alloc] initWithTitle:@"赛博"];
    self.styleButtons = @[pretty, ancient, cyber];

    UIStackView *chipStack = [[UIStackView alloc] initWithArrangedSubviews:self.styleButtons];
    chipStack.translatesAutoresizingMaskIntoConstraints = NO;
    chipStack.axis = UILayoutConstraintAxisHorizontal;
    chipStack.spacing = 10;
    chipStack.distribution = UIStackViewDistributionFillEqually;
    [self.cardView addSubview:chipStack];

    for (NGStyleChipButton *button in self.styleButtons) {
        [button addTarget:self action:@selector(styleTapped:) forControlEvents:UIControlEventTouchUpInside];
        [button updateSelectedState:[[button titleForState:UIControlStateNormal] isEqualToString:self.currentStyle]];
    }

    self.numberSwitchLabel = [self makeLabel:@"附加数字后缀" font:[UIFont systemFontOfSize:15 weight:UIFontWeightMedium] alpha:0.95];
    self.numberSwitch = [[UISwitch alloc] init];
    self.numberSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    self.numberSwitch.onTintColor = [UIColor colorWithRed:0.42 green:0.39 blue:0.98 alpha:1.0];

    UIView *switchContainer = [[UIView alloc] init];
    switchContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [switchContainer addSubview:self.numberSwitchLabel];
    [switchContainer addSubview:self.numberSwitch];
    [self.cardView addSubview:switchContainer];

    self.generateButton = [self makeActionButton:@"生成新网名" icon:@"sparkles" selector:@selector(generateNicknameTapped)];
    [self.cardView addSubview:self.generateButton];

    self.feedAdContainerView = [[UIView alloc] init];
    self.feedAdContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.feedAdContainerView.backgroundColor = [UIColor colorWithRed:0.95 green:0.96 blue:1 alpha:1.0];
    self.feedAdContainerView.layer.cornerRadius = 14;
    self.feedAdContainerView.layer.borderWidth = 1;
    self.feedAdContainerView.layer.borderColor = [UIColor colorWithRed:0.80 green:0.84 blue:1 alpha:1.0].CGColor;

    UILabel *feedAdTitleLabel = [[UILabel alloc] init];
    feedAdTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    feedAdTitleLabel.text = @"首页信息流广告位";
    feedAdTitleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    feedAdTitleLabel.textAlignment = NSTextAlignmentCenter;

    UILabel *feedAdDetailLabel = [[UILabel alloc] init];
    feedAdDetailLabel.translatesAutoresizingMaskIntoConstraints = NO;
    feedAdDetailLabel.text = @"可替换为信息流广告 UIView（AdMob / 穿山甲 / 优量汇）";
    feedAdDetailLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    feedAdDetailLabel.textColor = UIColor.secondaryLabelColor;
    feedAdDetailLabel.numberOfLines = 0;
    feedAdDetailLabel.textAlignment = NSTextAlignmentCenter;

    [self.feedAdContainerView addSubview:feedAdTitleLabel];
    [self.feedAdContainerView addSubview:feedAdDetailLabel];
    [self.view addSubview:self.feedAdContainerView];

    [NSLayoutConstraint activateConstraints:@[
        [blurView.topAnchor constraintEqualToAnchor:self.cardView.topAnchor],
        [blurView.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor],
        [blurView.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor],
        [blurView.bottomAnchor constraintEqualToAnchor:self.cardView.bottomAnchor],

        [self.cardView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.cardView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [self.cardView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],

        [self.titleLabel.topAnchor constraintEqualToAnchor:self.cardView.topAnchor constant:28],
        [self.titleLabel.centerXAnchor constraintEqualToAnchor:self.cardView.centerXAnchor],

        [self.subtitleLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:8],
        [self.subtitleLabel.centerXAnchor constraintEqualToAnchor:self.cardView.centerXAnchor],

        [self.nicknameLabel.topAnchor constraintEqualToAnchor:self.subtitleLabel.bottomAnchor constant:24],
        [self.nicknameLabel.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:20],
        [self.nicknameLabel.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-20],

        [chipStack.topAnchor constraintEqualToAnchor:self.nicknameLabel.bottomAnchor constant:22],
        [chipStack.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:20],
        [chipStack.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-20],

        [switchContainer.topAnchor constraintEqualToAnchor:chipStack.bottomAnchor constant:16],
        [switchContainer.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:20],
        [switchContainer.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-20],
        [switchContainer.heightAnchor constraintEqualToConstant:31],

        [self.numberSwitchLabel.centerYAnchor constraintEqualToAnchor:switchContainer.centerYAnchor],
        [self.numberSwitchLabel.leadingAnchor constraintEqualToAnchor:switchContainer.leadingAnchor],

        [self.numberSwitch.centerYAnchor constraintEqualToAnchor:switchContainer.centerYAnchor],
        [self.numberSwitch.trailingAnchor constraintEqualToAnchor:switchContainer.trailingAnchor],

        [self.generateButton.topAnchor constraintEqualToAnchor:switchContainer.bottomAnchor constant:16],
        [self.generateButton.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:20],
        [self.generateButton.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-20],
        [self.generateButton.heightAnchor constraintEqualToConstant:50],
        [self.generateButton.bottomAnchor constraintEqualToAnchor:self.cardView.bottomAnchor constant:-24],

        [self.feedAdContainerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.feedAdContainerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [self.feedAdContainerView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-12],
        [self.feedAdContainerView.heightAnchor constraintEqualToConstant:86],

        [feedAdTitleLabel.topAnchor constraintEqualToAnchor:self.feedAdContainerView.topAnchor constant:12],
        [feedAdTitleLabel.leadingAnchor constraintEqualToAnchor:self.feedAdContainerView.leadingAnchor constant:10],
        [feedAdTitleLabel.trailingAnchor constraintEqualToAnchor:self.feedAdContainerView.trailingAnchor constant:-10],

        [feedAdDetailLabel.topAnchor constraintEqualToAnchor:feedAdTitleLabel.bottomAnchor constant:6],
        [feedAdDetailLabel.leadingAnchor constraintEqualToAnchor:self.feedAdContainerView.leadingAnchor constant:12],
        [feedAdDetailLabel.trailingAnchor constraintEqualToAnchor:self.feedAdContainerView.trailingAnchor constant:-12],
        [feedAdDetailLabel.bottomAnchor constraintLessThanOrEqualToAnchor:self.feedAdContainerView.bottomAnchor constant:-10]
    ]];
}

- (UILabel *)makeLabel:(NSString *)text font:(UIFont *)font alpha:(CGFloat)alpha {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = text;
    label.textColor = [UIColor colorWithWhite:1 alpha:alpha];
    label.font = font;
    return label;
}

- (UIButton *)makeActionButton:(NSString *)title icon:(NSString *)icon selector:(SEL)selector {
    UIButtonConfiguration *configuration = [UIButtonConfiguration filledButtonConfiguration];
    configuration.title = title;
    configuration.baseForegroundColor = UIColor.whiteColor;
    configuration.baseBackgroundColor = [UIColor colorWithRed:0.39 green:0.34 blue:0.95 alpha:1.0];
    configuration.cornerStyle = UIButtonConfigurationCornerStyleLarge;
    configuration.imagePadding = 8;
    configuration.contentInsets = NSDirectionalEdgeInsetsMake(12, 14, 12, 14);

    if ([UIImage respondsToSelector:@selector(systemImageNamed:)]) {
        configuration.image = [UIImage systemImageNamed:icon];
    }

    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.configuration = configuration;
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)styleTapped:(NGStyleChipButton *)sender {
    NSString *newStyle = [sender titleForState:UIControlStateNormal];
    self.currentStyle = newStyle;
    for (NGStyleChipButton *button in self.styleButtons) {
        BOOL selected = [[button titleForState:UIControlStateNormal] isEqualToString:newStyle];
        [button updateSelectedState:selected];
    }
    [self refreshNicknameWithoutNavigation];
}

- (void)generateNicknameTapped {
    NSString *nickname = [self refreshNicknameWithoutNavigation];
    [self openDisplayPageWithNickname:nickname];
    [self maybeRequestReview];
}

- (void)restoreLastNicknamePreview {
    NSString *latestNickname = self.generator.latestNickname;
    if (latestNickname.length > 0) {
        self.nicknameLabel.text = latestNickname;
    } else {
        [self refreshNicknameWithoutNavigation];
    }
}

- (NSString *)refreshNicknameWithoutNavigation {
    NSString *nickname = [self.generator generateNicknameWithStyle:self.currentStyle includeNumber:self.numberSwitch.isOn];
    self.nicknameLabel.text = nickname;
    return nickname;
}

- (void)openDisplayPageWithNickname:(NSString *)nickname {
    NGDisplayViewController *displayVC = [[NGDisplayViewController alloc] initWithNickname:nickname];
    displayVC.hidesBottomBarWhenPushed = YES;
    if (self.navigationController) {
        [self.navigationController pushViewController:displayVC animated:YES];
    } else {
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:displayVC];
        [self presentViewController:navigationController animated:YES completion:nil];
    }
}

- (void)maybeRequestReview {
    self.generationCount += 1;
    [[NSUserDefaults standardUserDefaults] setInteger:self.generationCount forKey:@"ng_generation_count"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    if (self.generationCount == 3 || self.generationCount % 8 == 0) {
        if (@available(iOS 14.0, *)) {
            UIWindowScene *windowScene = self.view.window.windowScene;
            if (windowScene) {
                [SKStoreReviewController requestReviewInScene:windowScene];
            }
        } else {
            [SKStoreReviewController requestReview];
        }
    }
}

@end
