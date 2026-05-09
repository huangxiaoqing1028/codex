#import "MainMenuViewController.h"
#import "GameViewController.h"
#import "SettingsViewController.h"
#import "ProgressManager.h"
#import "AchievementViewController.h"
#import "GuideOverlayView.h"
#import "System/BalanceLoader.h"

@interface MainMenuViewController ()
@property UILabel *status;
@end

@implementation MainMenuViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    [[BalanceLoader shared] loadTables];
    CAGradientLayer *bg=[CAGradientLayer layer]; bg.frame=self.view.bounds; bg.colors=@[(id)[UIColor colorWithRed:0.07 green:0.08 blue:0.14 alpha:1].CGColor,(id)[UIColor colorWithRed:0.15 green:0.09 blue:0.10 alpha:1].CGColor]; [self.view.layer addSublayer:bg];

    UILabel *t=[UILabel new]; t.translatesAutoresizingMaskIntoConstraints=NO; t.text=@"横扫天下-大极品"; t.textColor=UIColor.whiteColor; t.font=[UIFont boldSystemFontOfSize:36]; [self.view addSubview:t];
    UIButton*(^mk)(NSString*,SEL)=^UIButton*(NSString*title,SEL sel){ UIButton*b=[UIButton buttonWithType:UIButtonTypeSystem]; b.translatesAutoresizingMaskIntoConstraints=NO; b.backgroundColor=[UIColor colorWithRed:0.86 green:0.27 blue:0.18 alpha:1]; [b setTitle:title forState:UIControlStateNormal]; [b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal]; b.titleLabel.font=[UIFont boldSystemFontOfSize:21]; b.layer.cornerRadius=14; [b addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside]; [self.view addSubview:b]; return b;};
    UIButton *b1=mk(@"开始征战",@selector(start)); UIButton *b2=mk(@"成就",@selector(openAchievement)); UIButton *b3=mk(@"设置",@selector(openSettings));
    self.status=[UILabel new]; self.status.translatesAutoresizingMaskIntoConstraints=NO; self.status.textColor=[UIColor colorWithWhite:1 alpha:0.88]; self.status.numberOfLines=0; self.status.font=[UIFont monospacedDigitSystemFontOfSize:16 weight:UIFontWeightMedium]; [self.view addSubview:self.status];
    UILayoutGuide *g=self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[[t.topAnchor constraintEqualToAnchor:g.topAnchor constant:44],[t.centerXAnchor constraintEqualToAnchor:g.centerXAnchor],[b1.topAnchor constraintEqualToAnchor:t.bottomAnchor constant:52],[b1.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:36],[b1.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-36],[b1.heightAnchor constraintEqualToConstant:56],[b2.topAnchor constraintEqualToAnchor:b1.bottomAnchor constant:16],[b2.leadingAnchor constraintEqualToAnchor:b1.leadingAnchor],[b2.trailingAnchor constraintEqualToAnchor:b1.trailingAnchor],[b2.heightAnchor constraintEqualToConstant:56],[b3.topAnchor constraintEqualToAnchor:b2.bottomAnchor constant:16],[b3.leadingAnchor constraintEqualToAnchor:b1.leadingAnchor],[b3.trailingAnchor constraintEqualToAnchor:b1.trailingAnchor],[b3.heightAnchor constraintEqualToConstant:56],[self.status.topAnchor constraintEqualToAnchor:b3.bottomAnchor constant:24],[self.status.leadingAnchor constraintEqualToAnchor:b1.leadingAnchor],[self.status.trailingAnchor constraintEqualToAnchor:b1.trailingAnchor]]];
}
- (void)viewDidLayoutSubviews { [super viewDidLayoutSubviews]; ((CAGradientLayer *)self.view.layer.sublayers.firstObject).frame=self.view.bounds; }
- (void)viewDidAppear:(BOOL)animated { [super viewDidAppear:animated]; if (![[NSUserDefaults standardUserDefaults] boolForKey:@"guide_done"]) { GuideOverlayView *g=[GuideOverlayView new]; [g showInView:self.view text:@"点击【开始征战】进入章节战斗。命中目标提升战力，结束后结算金币和成就。" onDismiss:^{ [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"guide_done"]; }]; } }
- (void)viewWillAppear:(BOOL)animated { [super viewWillAppear:animated]; ProgressManager*p=[ProgressManager shared]; NSInteger reward=[p collectOfflineReward]; NSDictionary *chapter=[BalanceLoader shared].chapters.firstObject ?: @{}; self.status.text=[NSString stringWithFormat:@"金币:%ld\n历史最高:%ld\n离线收益:+%ld\n当前章节:%@",(long)p.gold,(long)p.bestScore,(long)reward,chapter[@"name"]?:@"-"]; }
- (void)start { [self.navigationController pushViewController:[GameViewController new] animated:YES]; }
- (void)openAchievement { [self.navigationController pushViewController:[AchievementViewController new] animated:YES]; }
- (void)openSettings { [self.navigationController pushViewController:[SettingsViewController new] animated:YES]; }
@end
