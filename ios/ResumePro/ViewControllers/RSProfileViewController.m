#import "RSProfileViewController.h"
#import "RSPaywallViewController.h"
#import "RSSubscriptionService.h"
#import "RSTheme.h"

@interface RSProfileViewController ()
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *descLabel;
@end

@implementation RSProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"会员中心";
    self.view.backgroundColor = [RSTheme bgPrimary];

    UIView *card = [[UIView alloc] init];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    card.backgroundColor = [RSTheme cardBackground];
    card.layer.cornerRadius = 16;
    card.layer.borderWidth = 1;
    card.layer.borderColor = [RSTheme border].CGColor;

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightBold];
    self.statusLabel.textColor = [RSTheme textPrimary];

    self.descLabel = [[UILabel alloc] init];
    self.descLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.descLabel.numberOfLines = 0;
    self.descLabel.font = [RSTheme bodyFont];
    self.descLabel.textColor = [RSTheme textSecondary];
    self.descLabel.text = @"升级 Pro 解锁高端模板、无水印导出、后续 AI 优化功能。";

    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [btn setTitle:@"管理订阅" forState:UIControlStateNormal];
    btn.backgroundColor = [RSTheme accentGold];
    [btn setTitleColor:[RSTheme bgPrimary] forState:UIControlStateNormal];
    btn.layer.cornerRadius = 12;
    btn.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [btn addTarget:self action:@selector(openPaywall) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:card];
    [card addSubview:self.statusLabel];
    [card addSubview:self.descLabel];
    [card addSubview:btn];

    [NSLayoutConstraint activateConstraints:@[
        [card.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:20],
        [card.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [card.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],

        [self.statusLabel.topAnchor constraintEqualToAnchor:card.topAnchor constant:20],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],

        [self.descLabel.topAnchor constraintEqualToAnchor:self.statusLabel.bottomAnchor constant:10],
        [self.descLabel.leadingAnchor constraintEqualToAnchor:self.statusLabel.leadingAnchor],
        [self.descLabel.trailingAnchor constraintEqualToAnchor:self.statusLabel.trailingAnchor],

        [btn.topAnchor constraintEqualToAnchor:self.descLabel.bottomAnchor constant:18],
        [btn.leadingAnchor constraintEqualToAnchor:self.statusLabel.leadingAnchor],
        [btn.trailingAnchor constraintEqualToAnchor:self.statusLabel.trailingAnchor],
        [btn.heightAnchor constraintEqualToConstant:48],
        [btn.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-16],
    ]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:RSSubscriptionStatusDidChangeNotification object:nil];
    [self refresh];
}

- (void)refresh {
    self.statusLabel.text = [RSSubscriptionService shared].isPro ? @"当前计划：Pro Annual" : @"当前计划：Free";
}

- (void)openPaywall {
    [self.navigationController pushViewController:[[RSPaywallViewController alloc] init] animated:YES];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
