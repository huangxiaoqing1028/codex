#import "RSPaywallViewController.h"
#import "RSSubscriptionService.h"

@implementation RSPaywallViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.title = @"开通 Pro";

    UILabel *title = [[UILabel alloc] init];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = @"专业模板 / 无水印 PDF / 优先支持";
    title.numberOfLines = 0;
    title.font = [UIFont boldSystemFontOfSize:24];

    UIButton *buy = [UIButton buttonWithType:UIButtonTypeSystem];
    buy.translatesAutoresizingMaskIntoConstraints = NO;
    [buy setTitle:@"立即开通" forState:UIControlStateNormal];
    [buy addTarget:self action:@selector(onBuy) forControlEvents:UIControlEventTouchUpInside];
    buy.backgroundColor = [UIColor colorWithRed:0.07 green:0.09 blue:0.12 alpha:1.0];
    [buy setTitleColor:[UIColor colorWithRed:0.78 green:0.64 blue:0.42 alpha:1.0] forState:UIControlStateNormal];
    buy.layer.cornerRadius = 12;

    UIButton *restore = [UIButton buttonWithType:UIButtonTypeSystem];
    restore.translatesAutoresizingMaskIntoConstraints = NO;
    [restore setTitle:@"恢复购买" forState:UIControlStateNormal];
    [restore addTarget:self action:@selector(onRestore) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:title];
    [self.view addSubview:buy];
    [self.view addSubview:restore];

    [NSLayoutConstraint activateConstraints:@[
        [title.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:40],
        [title.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [title.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],

        [buy.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:28],
        [buy.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [buy.trailingAnchor constraintEqualToAnchor:title.trailingAnchor],
        [buy.heightAnchor constraintEqualToConstant:50],

        [restore.topAnchor constraintEqualToAnchor:buy.bottomAnchor constant:12],
        [restore.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
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
