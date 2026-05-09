#import "MainMenuViewController.h"

#import <QuartzCore/QuartzCore.h>

#import "AchievementViewController.h"
#import "GameViewController.h"
#import "GuideOverlayView.h"
#import "ProgressManager.h"
#import "SettingsViewController.h"
#import "System/BalanceLoader.h"

@interface MainMenuViewController ()
@property (nonatomic, strong) UILabel *status;
@end

@implementation MainMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [[BalanceLoader shared] loadTables];

    CAGradientLayer *bg = [CAGradientLayer layer];
    bg.frame = self.view.bounds;
    bg.colors = @[
        (id)[UIColor colorWithRed:0.07 green:0.08 blue:0.14 alpha:1].CGColor,
        (id)[UIColor colorWithRed:0.15 green:0.09 blue:0.10 alpha:1].CGColor
    ];
    [self.view.layer addSublayer:bg];

    UILabel *titleLabel = [UILabel new];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.text = @"横扫天下-大极品";
    titleLabel.textColor = UIColor.whiteColor;
    titleLabel.font = [UIFont boldSystemFontOfSize:36];
    [self.view addSubview:titleLabel];

    UIButton *(^makeButton)(NSString *, SEL) = ^UIButton *(NSString *title, SEL sel) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        button.backgroundColor = [UIColor colorWithRed:0.86 green:0.27 blue:0.18 alpha:1];
        [button setTitle:title forState:UIControlStateNormal];
        [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont boldSystemFontOfSize:21];
        button.layer.cornerRadius = 14;
        [button addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
        return button;
    };

    UIButton *startButton = makeButton(@"开始征战", @selector(start));
    UIButton *achievementButton = makeButton(@"成就", @selector(openAchievement));
    UIButton *settingsButton = makeButton(@"设置", @selector(openSettings));

    self.status = [UILabel new];
    self.status.translatesAutoresizingMaskIntoConstraints = NO;
    self.status.textColor = [UIColor colorWithWhite:1 alpha:0.88];
    self.status.numberOfLines = 0;
    self.status.font = [UIFont monospacedDigitSystemFontOfSize:16 weight:UIFontWeightMedium];
    [self.view addSubview:self.status];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [titleLabel.topAnchor constraintEqualToAnchor:safe.topAnchor constant:44],
        [titleLabel.centerXAnchor constraintEqualToAnchor:safe.centerXAnchor],

        [startButton.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:52],
        [startButton.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:36],
        [startButton.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-36],
        [startButton.heightAnchor constraintEqualToConstant:56],

        [achievementButton.topAnchor constraintEqualToAnchor:startButton.bottomAnchor constant:16],
        [achievementButton.leadingAnchor constraintEqualToAnchor:startButton.leadingAnchor],
        [achievementButton.trailingAnchor constraintEqualToAnchor:startButton.trailingAnchor],
        [achievementButton.heightAnchor constraintEqualToConstant:56],

        [settingsButton.topAnchor constraintEqualToAnchor:achievementButton.bottomAnchor constant:16],
        [settingsButton.leadingAnchor constraintEqualToAnchor:startButton.leadingAnchor],
        [settingsButton.trailingAnchor constraintEqualToAnchor:startButton.trailingAnchor],
        [settingsButton.heightAnchor constraintEqualToConstant:56],

        [self.status.topAnchor constraintEqualToAnchor:settingsButton.bottomAnchor constant:24],
        [self.status.leadingAnchor constraintEqualToAnchor:startButton.leadingAnchor],
        [self.status.trailingAnchor constraintEqualToAnchor:startButton.trailingAnchor]
    ]];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    ((CAGradientLayer *)self.view.layer.sublayers.firstObject).frame = self.view.bounds;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"guide_done"]) {
        GuideOverlayView *guide = [GuideOverlayView new];
        [guide showInView:self.view
                     text:@"点击【开始征战】进入章节战斗。命中目标提升战力，结束后结算金币和成就。"
                onDismiss:^{
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"guide_done"];
                }];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    ProgressManager *progress = [ProgressManager shared];
    NSInteger reward = [progress collectOfflineReward];
    NSDictionary *chapter = [BalanceLoader shared].chapters.firstObject ?: @{};
    self.status.text = [NSString stringWithFormat:@"金币:%ld\n历史最高:%ld\n离线收益:+%ld\n当前章节:%@",
                        (long)progress.gold,
                        (long)progress.bestScore,
                        (long)reward,
                        chapter[@"name"] ?: @"-"];
}

- (void)start { [self.navigationController pushViewController:[GameViewController new] animated:YES]; }
- (void)openAchievement { [self.navigationController pushViewController:[AchievementViewController new] animated:YES]; }
- (void)openSettings { [self.navigationController pushViewController:[SettingsViewController new] animated:YES]; }

@end
