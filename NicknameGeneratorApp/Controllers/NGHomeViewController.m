#import "NGHomeViewController.h"
#import "NGNicknameGenerator.h"
#import "NGStyleChipButton.h"

@interface NGHomeViewController ()
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *nicknameLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIButton *generateButton;
@property (nonatomic, strong) UIButton *copyButton;
@property (nonatomic, strong) UIButton *favoriteButton;
@property (nonatomic, strong) UISwitch *numberSwitch;
@property (nonatomic, strong) UILabel *numberSwitchLabel;
@property (nonatomic, strong) UILabel *historyTitle;
@property (nonatomic, strong) UITextView *historyView;
@property (nonatomic, strong) NSArray<NGStyleChipButton *> *styleButtons;
@property (nonatomic, copy) NSString *currentStyle;
@property (nonatomic, strong) NGNicknameGenerator *generator;
@end

@implementation NGHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.currentStyle = @"唯美";
    self.generator = [[NGNicknameGenerator alloc] init];

    [self configureBackground];
    [self configureUI];
    [self generateNicknameTapped];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.gradientLayer.frame = self.view.bounds;
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
    self.subtitleLabel = [self makeLabel:@"一键生成可爱/古风/赛博风昵称" font:[UIFont systemFontOfSize:14 weight:UIFontWeightRegular] alpha:0.85];
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
    self.copyButton = [self makeActionButton:@"复制" icon:@"doc.on.doc" selector:@selector(copyTapped)];
    self.favoriteButton = [self makeActionButton:@"收藏" icon:@"heart" selector:@selector(favoriteTapped)];

    UIStackView *actionStack = [[UIStackView alloc] initWithArrangedSubviews:@[self.copyButton, self.favoriteButton]];
    actionStack.translatesAutoresizingMaskIntoConstraints = NO;
    actionStack.axis = UILayoutConstraintAxisHorizontal;
    actionStack.distribution = UIStackViewDistributionFillEqually;
    actionStack.spacing = 12;

    self.historyTitle = [self makeLabel:@"最近生成" font:[UIFont systemFontOfSize:16 weight:UIFontWeightSemibold] alpha:0.95];
    self.historyView = [[UITextView alloc] init];
    self.historyView.translatesAutoresizingMaskIntoConstraints = NO;
    self.historyView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.06];
    self.historyView.layer.cornerRadius = 14;
    self.historyView.textColor = [UIColor colorWithWhite:1 alpha:0.9];
    self.historyView.font = [UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightRegular];
    self.historyView.editable = NO;

    [self.cardView addSubview:self.generateButton];
    [self.cardView addSubview:actionStack];
    [self.cardView addSubview:self.historyTitle];
    [self.cardView addSubview:self.historyView];

    [NSLayoutConstraint activateConstraints:@[
        [blurView.topAnchor constraintEqualToAnchor:self.cardView.topAnchor],
        [blurView.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor],
        [blurView.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor],
        [blurView.bottomAnchor constraintEqualToAnchor:self.cardView.bottomAnchor],

        [self.cardView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.cardView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [self.cardView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:16],
        [self.cardView.bottomAnchor constraintLessThanOrEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-20],

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

        [actionStack.topAnchor constraintEqualToAnchor:self.generateButton.bottomAnchor constant:12],
        [actionStack.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:20],
        [actionStack.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-20],
        [actionStack.heightAnchor constraintEqualToConstant:44],

        [self.historyTitle.topAnchor constraintEqualToAnchor:actionStack.bottomAnchor constant:18],
        [self.historyTitle.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:20],

        [self.historyView.topAnchor constraintEqualToAnchor:self.historyTitle.bottomAnchor constant:8],
        [self.historyView.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:20],
        [self.historyView.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-20],
        [self.historyView.bottomAnchor constraintEqualToAnchor:self.cardView.bottomAnchor constant:-20],
        [self.historyView.heightAnchor constraintGreaterThanOrEqualToConstant:140]
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
    [self generateNicknameTapped];
}

- (void)generateNicknameTapped {
    NSString *nickname = [self.generator generateNicknameWithStyle:self.currentStyle includeNumber:self.numberSwitch.isOn];
    self.nicknameLabel.text = nickname;
    [self syncFavoriteButton];
    [self renderHistory];
}

- (void)copyTapped {
    if (self.nicknameLabel.text.length == 0) {
        return;
    }

    [UIPasteboard generalPasteboard].string = self.nicknameLabel.text;
    [self showToast:@"已复制到剪贴板"]; 
}

- (void)favoriteTapped {
    if (self.nicknameLabel.text.length == 0) {
        return;
    }

    [self.generator toggleFavorite:self.nicknameLabel.text];
    [self syncFavoriteButton];
    [self showToast:[self.generator isFavorite:self.nicknameLabel.text] ? @"已加入收藏" : @"已取消收藏"];
}

- (void)syncFavoriteButton {
    BOOL isFavorite = [self.generator isFavorite:self.nicknameLabel.text ?: @""];
    NSString *title = isFavorite ? @"取消收藏" : @"收藏";
    NSString *icon = isFavorite ? @"heart.fill" : @"heart";
    self.favoriteButton.configuration.title = title;
    if ([UIImage respondsToSelector:@selector(systemImageNamed:)]) {
        self.favoriteButton.configuration.image = [UIImage systemImageNamed:icon];
    }
}

- (void)renderHistory {
    NSMutableArray<NSString *> *lines = [NSMutableArray array];

    if (self.generator.favoriteNicknames.count > 0) {
        [lines addObject:@"★ 收藏"]; 
        for (NSString *nickname in self.generator.favoriteNicknames) {
            [lines addObject:[NSString stringWithFormat:@"- %@", nickname]];
        }
        [lines addObject:@""];
    }

    [lines addObject:@"⌛ 最近"]; 
    for (NSString *nickname in self.generator.recentNicknames) {
        [lines addObject:[NSString stringWithFormat:@"- %@", nickname]];
    }

    self.historyView.text = [lines componentsJoinedByString:@"\n"];
}

- (void)showToast:(NSString *)message {
    UILabel *toast = [[UILabel alloc] init];
    toast.translatesAutoresizingMaskIntoConstraints = NO;
    toast.text = message;
    toast.textColor = UIColor.whiteColor;
    toast.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    toast.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
    toast.layer.cornerRadius = 10;
    toast.clipsToBounds = YES;
    toast.textAlignment = NSTextAlignmentCenter;

    [self.view addSubview:toast];
    [NSLayoutConstraint activateConstraints:@[
        [toast.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [toast.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-20],
        [toast.widthAnchor constraintLessThanOrEqualToConstant:220],
        [toast.heightAnchor constraintEqualToConstant:36]
    ]];

    toast.alpha = 0;
    [UIView animateWithDuration:0.22 animations:^{
        toast.alpha = 1;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.22 delay:1.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            toast.alpha = 0;
        } completion:^(BOOL finished2) {
            [toast removeFromSuperview];
        }];
    }];
}

@end
