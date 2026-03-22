#import "SceneDelegate.h"
#import "ViewControllers/ResumeFormViewController.h"

@interface LandingViewController : UIViewController
@end

@interface LandingViewController ()
@property (nonatomic, strong) UIView *heroCard;
@end

@implementation LandingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"ResumeOC";
    self.view.backgroundColor = [UIColor colorWithRed:0.95 green:0.97 blue:1 alpha:1];
    [self buildUI];
}

- (void)buildUI {
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.colors = @[
        (__bridge id)[UIColor colorWithRed:0.33 green:0.40 blue:1 alpha:1].CGColor,
        (__bridge id)[UIColor colorWithRed:0.60 green:0.38 blue:1 alpha:1].CGColor
    ];
    gradient.startPoint = CGPointMake(0, 0);
    gradient.endPoint = CGPointMake(1, 1);

    self.heroCard = [[UIView alloc] init];
    self.heroCard.translatesAutoresizingMaskIntoConstraints = NO;
    self.heroCard.layer.cornerRadius = 24;
    self.heroCard.layer.masksToBounds = YES;
    [self.view addSubview:self.heroCard];

    [self.heroCard.layer insertSublayer:gradient atIndex:0];

    UILabel *badge = [[UILabel alloc] init];
    badge.translatesAutoresizingMaskIntoConstraints = NO;
    badge.text = @"AI Resume Studio";
    badge.textColor = [UIColor colorWithWhite:1 alpha:0.95];
    badge.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    badge.backgroundColor = [UIColor colorWithWhite:1 alpha:0.18];
    badge.textAlignment = NSTextAlignmentCenter;
    badge.layer.cornerRadius = 12;
    badge.layer.masksToBounds = YES;
    [self.heroCard addSubview:badge];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.text = @"打造你的商业简历";
    titleLabel.numberOfLines = 2;
    titleLabel.textColor = UIColor.whiteColor;
    titleLabel.font = [UIFont systemFontOfSize:30 weight:UIFontWeightBold];
    [self.heroCard addSubview:titleLabel];

    UILabel *subtitleLabel = [[UILabel alloc] init];
    subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    subtitleLabel.text = @"多页面信息录入，自动生成高质感 PDF 简历。";
    subtitleLabel.numberOfLines = 0;
    subtitleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.88];
    subtitleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    [self.heroCard addSubview:subtitleLabel];

    UIView *highlightCard = [[UIView alloc] init];
    highlightCard.translatesAutoresizingMaskIntoConstraints = NO;
    highlightCard.backgroundColor = UIColor.whiteColor;
    highlightCard.layer.cornerRadius = 18;
    highlightCard.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.12].CGColor;
    highlightCard.layer.shadowOpacity = 1;
    highlightCard.layer.shadowOffset = CGSizeMake(0, 8);
    highlightCard.layer.shadowRadius = 20;
    [self.view addSubview:highlightCard];

    UILabel *highlightTitle = [[UILabel alloc] init];
    highlightTitle.translatesAutoresizingMaskIntoConstraints = NO;
    highlightTitle.text = @"为什么选择它";
    highlightTitle.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    highlightTitle.textColor = [UIColor colorWithRed:0.10 green:0.13 blue:0.24 alpha:1.0];
    [highlightCard addSubview:highlightTitle];

    UILabel *highlightDesc = [[UILabel alloc] init];
    highlightDesc.translatesAutoresizingMaskIntoConstraints = NO;
    highlightDesc.text = @"• 6 大模块分步填写\n• 一键预览简历 PDF\n• 预览页右上角导出分享";
    highlightDesc.numberOfLines = 0;
    highlightDesc.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    highlightDesc.textColor = [UIColor colorWithRed:0.35 green:0.38 blue:0.47 alpha:1.0];
    [highlightCard addSubview:highlightDesc];

    UIButton *startButton = [UIButton buttonWithType:UIButtonTypeSystem];
    startButton.translatesAutoresizingMaskIntoConstraints = NO;
    [startButton setTitle:@"创建简历" forState:UIControlStateNormal];
    [startButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    startButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    startButton.backgroundColor = [UIColor colorWithRed:0.26 green:0.33 blue:1 alpha:1];
    startButton.layer.cornerRadius = 16;
    startButton.layer.shadowColor = [UIColor colorWithRed:0.26 green:0.33 blue:1 alpha:0.35].CGColor;
    startButton.layer.shadowOpacity = 1;
    startButton.layer.shadowOffset = CGSizeMake(0, 10);
    startButton.layer.shadowRadius = 20;
    [startButton addTarget:self action:@selector(startTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:startButton];

    UILabel *footer = [[UILabel alloc] init];
    footer.translatesAutoresizingMaskIntoConstraints = NO;
    footer.text = @"像大厂一样的简历体验，从这里开始";
    footer.textColor = [UIColor colorWithRed:0.50 green:0.53 blue:0.60 alpha:1];
    footer.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    footer.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:footer];

    [NSLayoutConstraint activateConstraints:@[
        [self.heroCard.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:18],
        [self.heroCard.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:18],
        [self.heroCard.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-18],
        [self.heroCard.heightAnchor constraintEqualToConstant:250],

        [badge.topAnchor constraintEqualToAnchor:self.heroCard.topAnchor constant:20],
        [badge.leadingAnchor constraintEqualToAnchor:self.heroCard.leadingAnchor constant:20],
        [badge.widthAnchor constraintEqualToConstant:116],
        [badge.heightAnchor constraintEqualToConstant:24],

        [titleLabel.topAnchor constraintEqualToAnchor:badge.bottomAnchor constant:14],
        [titleLabel.leadingAnchor constraintEqualToAnchor:self.heroCard.leadingAnchor constant:20],
        [titleLabel.trailingAnchor constraintEqualToAnchor:self.heroCard.trailingAnchor constant:-20],

        [subtitleLabel.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:10],
        [subtitleLabel.leadingAnchor constraintEqualToAnchor:self.heroCard.leadingAnchor constant:20],
        [subtitleLabel.trailingAnchor constraintEqualToAnchor:self.heroCard.trailingAnchor constant:-20],

        [highlightCard.topAnchor constraintEqualToAnchor:self.heroCard.bottomAnchor constant:18],
        [highlightCard.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:18],
        [highlightCard.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-18],

        [highlightTitle.topAnchor constraintEqualToAnchor:highlightCard.topAnchor constant:16],
        [highlightTitle.leadingAnchor constraintEqualToAnchor:highlightCard.leadingAnchor constant:16],
        [highlightTitle.trailingAnchor constraintEqualToAnchor:highlightCard.trailingAnchor constant:-16],

        [highlightDesc.topAnchor constraintEqualToAnchor:highlightTitle.bottomAnchor constant:10],
        [highlightDesc.leadingAnchor constraintEqualToAnchor:highlightCard.leadingAnchor constant:16],
        [highlightDesc.trailingAnchor constraintEqualToAnchor:highlightCard.trailingAnchor constant:-16],
        [highlightDesc.bottomAnchor constraintEqualToAnchor:highlightCard.bottomAnchor constant:-16],

        [startButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:18],
        [startButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-18],
        [startButton.bottomAnchor constraintEqualToAnchor:footer.topAnchor constant:-12],
        [startButton.heightAnchor constraintEqualToConstant:56],

        [footer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:18],
        [footer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-18],
        [footer.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-10],
        [highlightCard.bottomAnchor constraintLessThanOrEqualToAnchor:startButton.topAnchor constant:-20]
    ]];

    dispatch_async(dispatch_get_main_queue(), ^{
        gradient.frame = self.heroCard.bounds;
    });
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CALayer *firstLayer = self.heroCard.layer.sublayers.firstObject;
    if ([firstLayer isKindOfClass:[CAGradientLayer class]]) {
        firstLayer.frame = self.heroCard.bounds;
    }
}

- (void)startTapped {
    ResumeFormViewController *formVC = [[ResumeFormViewController alloc] init];
    [self.navigationController pushViewController:formVC animated:YES];
}

@end

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:[UIWindowScene class]]) {
        return;
    }

    UIWindowScene *windowScene = (UIWindowScene *)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];

    LandingViewController *rootVC = [[LandingViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:rootVC];
    nav.navigationBar.prefersLargeTitles = NO;

    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
}

@end
