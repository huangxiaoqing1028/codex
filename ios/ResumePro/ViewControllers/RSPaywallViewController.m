#import "RSPaywallViewController.h"
#import "RSSubscriptionService.h"
#import "RSTheme.h"

@implementation RSPaywallViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [RSTheme bgPrimary];
    self.title = @"Resume Pro 会员";

    UIView *hero = [[UIView alloc] init];
    hero.translatesAutoresizingMaskIntoConstraints = NO;
    hero.backgroundColor = [RSTheme cardBackground];
    hero.layer.cornerRadius = 18;
    hero.layer.borderWidth = 1;
    hero.layer.borderColor = [RSTheme border].CGColor;

    UILabel *title = [[UILabel alloc] init];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = @"解锁高端商务模板与无水印导出";
    title.numberOfLines = 0;
    title.font = [RSTheme titleFont];
    title.textColor = [RSTheme textPrimary];

    UILabel *feature = [[UILabel alloc] init];
    feature.translatesAutoresizingMaskIntoConstraints = NO;
    feature.numberOfLines = 0;
    feature.textColor = [RSTheme textSecondary];
    feature.font = [RSTheme bodyFont];
    feature.text = @"• 30+ 商务专业模板\n• 一键导出高分辨率 PDF\n• 多端同步与持续更新\n• VIP 客服支持";

    UIButton *buy = [UIButton buttonWithType:UIButtonTypeSystem];
    buy.translatesAutoresizingMaskIntoConstraints = NO;
    [buy setTitle:@"立即开通 Pro ¥98/年" forState:UIControlStateNormal];
    [buy setTitleColor:[RSTheme bgPrimary] forState:UIControlStateNormal];
    buy.backgroundColor = [RSTheme accentGold];
    buy.layer.cornerRadius = 14;
    buy.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightBold];
    [buy addTarget:self action:@selector(onBuy) forControlEvents:UIControlEventTouchUpInside];

    UIButton *restore = [UIButton buttonWithType:UIButtonTypeSystem];
    restore.translatesAutoresizingMaskIntoConstraints = NO;
    [restore setTitle:@"恢复购买" forState:UIControlStateNormal];
    [restore setTitleColor:[RSTheme textSecondary] forState:UIControlStateNormal];
    [restore addTarget:self action:@selector(onRestore) forControlEvents:UIControlEventTouchUpInside];

    UILabel *legal = [[UILabel alloc] init];
    legal.translatesAutoresizingMaskIntoConstraints = NO;
    legal.numberOfLines = 0;
    legal.font = [UIFont systemFontOfSize:11];
    legal.textColor = [RSTheme textSecondary];
    legal.text = @"订阅将自动续费，可在 iOS 设置中管理。继续即代表同意服务条款与隐私政策。";

    [hero addSubview:title];
    [hero addSubview:feature];
    [hero addSubview:buy];
    [hero addSubview:restore];
    [hero addSubview:legal];
    [self.view addSubview:hero];

    [NSLayoutConstraint activateConstraints:@[
        [hero.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:20],
        [hero.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [hero.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],

        [title.topAnchor constraintEqualToAnchor:hero.topAnchor constant:20],
        [title.leadingAnchor constraintEqualToAnchor:hero.leadingAnchor constant:18],
        [title.trailingAnchor constraintEqualToAnchor:hero.trailingAnchor constant:-18],

        [feature.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:14],
        [feature.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [feature.trailingAnchor constraintEqualToAnchor:title.trailingAnchor],

        [buy.topAnchor constraintEqualToAnchor:feature.bottomAnchor constant:20],
        [buy.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [buy.trailingAnchor constraintEqualToAnchor:title.trailingAnchor],
        [buy.heightAnchor constraintEqualToConstant:52],

        [restore.topAnchor constraintEqualToAnchor:buy.bottomAnchor constant:12],
        [restore.centerXAnchor constraintEqualToAnchor:hero.centerXAnchor],

        [legal.topAnchor constraintEqualToAnchor:restore.bottomAnchor constant:14],
        [legal.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [legal.trailingAnchor constraintEqualToAnchor:title.trailingAnchor],
        [legal.bottomAnchor constraintEqualToAnchor:hero.bottomAnchor constant:-16],
    ]];
}

- (void)onBuy {
    [[RSSubscriptionService shared] purchaseProWithCompletion:^(BOOL success, NSString * _Nullable message) {
        [self show:message ?: (success ? @"成功" : @"失败")];
    }];
}

- (void)onRestore {
    [[RSSubscriptionService shared] restorePurchasesWithCompletion:^(BOOL success, NSString * _Nullable message) {
        [self show:message ?: (success ? @"成功" : @"失败")];
    }];
}

- (void)show:(NSString *)msg {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:msg preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
