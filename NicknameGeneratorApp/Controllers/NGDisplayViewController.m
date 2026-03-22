#import "NGDisplayViewController.h"
#import "NGNicknameGenerator.h"

@interface NGDisplayViewController ()
@property (nonatomic, copy) NSString *nickname;
@property (nonatomic, strong) NGNicknameGenerator *generator;
@property (nonatomic, strong) UIButton *copyButton;
@property (nonatomic, strong) UIButton *favoriteButton;
@end

@implementation NGDisplayViewController

- (instancetype)initWithNickname:(NSString *)nickname {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _nickname = [nickname copy];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.generator = [NGNicknameGenerator shared];
    self.title = @"结果";
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    UILabel *hintLabel = [[UILabel alloc] init];
    hintLabel.translatesAutoresizingMaskIntoConstraints = NO;
    hintLabel.text = @"本次生成网名";
    hintLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    hintLabel.textColor = UIColor.secondaryLabelColor;

    UILabel *nicknameLabel = [[UILabel alloc] init];
    nicknameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    nicknameLabel.font = [UIFont monospacedSystemFontOfSize:36 weight:UIFontWeightBold];
    nicknameLabel.textAlignment = NSTextAlignmentCenter;
    nicknameLabel.numberOfLines = 0;
    self.nickname = self.nickname.length > 0 ? self.nickname : self.generator.latestNickname;
    nicknameLabel.text = self.nickname;

    self.copyButton = [self makeActionButton:@"复制" icon:@"doc.on.doc" selector:@selector(copyTapped)];
    self.favoriteButton = [self makeActionButton:@"收藏" icon:@"heart" selector:@selector(favoriteTapped)];
    UIStackView *actionsStack = [[UIStackView alloc] initWithArrangedSubviews:@[self.copyButton, self.favoriteButton]];
    actionsStack.translatesAutoresizingMaskIntoConstraints = NO;
    actionsStack.axis = UILayoutConstraintAxisHorizontal;
    actionsStack.spacing = 12;
    actionsStack.distribution = UIStackViewDistributionFillEqually;

    UIView *adContainer = [[UIView alloc] init];
    adContainer.translatesAutoresizingMaskIntoConstraints = NO;
    adContainer.backgroundColor = [UIColor colorWithRed:0.95 green:0.96 blue:1 alpha:1.0];
    adContainer.layer.cornerRadius = 14;
    adContainer.layer.borderWidth = 1;
    adContainer.layer.borderColor = [UIColor colorWithRed:0.80 green:0.84 blue:1 alpha:1.0].CGColor;

    UILabel *adTitle = [[UILabel alloc] init];
    adTitle.translatesAutoresizingMaskIntoConstraints = NO;
    adTitle.text = @"广告位（可接入 AdMob / 穿山甲）";
    adTitle.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    adTitle.textAlignment = NSTextAlignmentCenter;

    UILabel *adDetail = [[UILabel alloc] init];
    adDetail.translatesAutoresizingMaskIntoConstraints = NO;
    adDetail.text = @"当前为占位视图，审核前替换为正式广告 SDK 组件";
    adDetail.textColor = UIColor.secondaryLabelColor;
    adDetail.numberOfLines = 0;
    adDetail.textAlignment = NSTextAlignmentCenter;
    adDetail.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];

    [adContainer addSubview:adTitle];
    [adContainer addSubview:adDetail];

    [self.view addSubview:hintLabel];
    [self.view addSubview:nicknameLabel];
    [self.view addSubview:actionsStack];
    [self.view addSubview:adContainer];

    [NSLayoutConstraint activateConstraints:@[
        [hintLabel.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:28],
        [hintLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],

        [nicknameLabel.topAnchor constraintEqualToAnchor:hintLabel.bottomAnchor constant:16],
        [nicknameLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [nicknameLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],

        [actionsStack.topAnchor constraintEqualToAnchor:nicknameLabel.bottomAnchor constant:20],
        [actionsStack.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [actionsStack.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [actionsStack.heightAnchor constraintEqualToConstant:44],

        [adContainer.topAnchor constraintEqualToAnchor:actionsStack.bottomAnchor constant:24],
        [adContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [adContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [adContainer.heightAnchor constraintEqualToConstant:140],

        [adTitle.topAnchor constraintEqualToAnchor:adContainer.topAnchor constant:24],
        [adTitle.leadingAnchor constraintEqualToAnchor:adContainer.leadingAnchor constant:12],
        [adTitle.trailingAnchor constraintEqualToAnchor:adContainer.trailingAnchor constant:-12],

        [adDetail.topAnchor constraintEqualToAnchor:adTitle.bottomAnchor constant:10],
        [adDetail.leadingAnchor constraintEqualToAnchor:adContainer.leadingAnchor constant:16],
        [adDetail.trailingAnchor constraintEqualToAnchor:adContainer.trailingAnchor constant:-16],
        [adDetail.bottomAnchor constraintLessThanOrEqualToAnchor:adContainer.bottomAnchor constant:-16]
    ]];

    [self syncFavoriteButton];
}

- (UIButton *)makeActionButton:(NSString *)title icon:(NSString *)icon selector:(SEL)selector {
    UIButtonConfiguration *configuration = [UIButtonConfiguration filledButtonConfiguration];
    configuration.title = title;
    configuration.baseForegroundColor = UIColor.whiteColor;
    configuration.baseBackgroundColor = [UIColor colorWithRed:0.39 green:0.34 blue:0.95 alpha:1.0];
    configuration.cornerStyle = UIButtonConfigurationCornerStyleMedium;
    configuration.imagePadding = 8;
    configuration.contentInsets = NSDirectionalEdgeInsetsMake(10, 12, 10, 12);
    if ([UIImage respondsToSelector:@selector(systemImageNamed:)]) {
        configuration.image = [UIImage systemImageNamed:icon];
    }

    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.configuration = configuration;
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)copyTapped {
    if (self.nickname.length == 0) {
        return;
    }
    [UIPasteboard generalPasteboard].string = self.nickname;
    [self showToast:@"已复制到剪贴板"];
}

- (void)favoriteTapped {
    if (self.nickname.length == 0) {
        return;
    }
    [self.generator toggleFavorite:self.nickname];
    [self syncFavoriteButton];
    BOOL isFavorite = [self.generator isFavorite:self.nickname];
    [self showToast:(isFavorite ? @"已加入收藏" : @"已取消收藏")];
}

- (void)syncFavoriteButton {
    BOOL isFavorite = [self.generator isFavorite:self.nickname ?: @""];
    self.favoriteButton.configuration.title = isFavorite ? @"取消收藏" : @"收藏";
    if ([UIImage respondsToSelector:@selector(systemImageNamed:)]) {
        self.favoriteButton.configuration.image = [UIImage systemImageNamed:(isFavorite ? @"heart.fill" : @"heart")];
    }
}

- (void)showToast:(NSString *)message {
    UILabel *toast = [[UILabel alloc] init];
    toast.translatesAutoresizingMaskIntoConstraints = NO;
    toast.text = message;
    toast.textColor = UIColor.whiteColor;
    toast.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    toast.backgroundColor = [UIColor colorWithWhite:0 alpha:0.75];
    toast.textAlignment = NSTextAlignmentCenter;
    toast.layer.cornerRadius = 10;
    toast.clipsToBounds = YES;

    [self.view addSubview:toast];
    [NSLayoutConstraint activateConstraints:@[
        [toast.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [toast.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-20],
        [toast.heightAnchor constraintEqualToConstant:36],
        [toast.widthAnchor constraintLessThanOrEqualToConstant:240]
    ]];

    toast.alpha = 0;
    [UIView animateWithDuration:0.2 animations:^{
        toast.alpha = 1;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 delay:1.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            toast.alpha = 0;
        } completion:^(BOOL finished2) {
            [toast removeFromSuperview];
        }];
    }];
}

@end
