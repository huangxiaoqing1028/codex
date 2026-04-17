#import "RSProfileViewController.h"
#import "RSPaywallViewController.h"
#import "RSSubscriptionService.h"

@interface RSProfileViewController ()
@property (nonatomic, strong) UILabel *statusLabel;
@end

@implementation RSProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"会员中心";
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];

    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [btn setTitle:@"管理订阅" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(openPaywall) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:self.statusLabel];
    [self.view addSubview:btn];

    [NSLayoutConstraint activateConstraints:@[
        [self.statusLabel.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:40],
        [self.statusLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [btn.topAnchor constraintEqualToAnchor:self.statusLabel.bottomAnchor constant:20],
        [btn.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    ]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:RSSubscriptionStatusDidChangeNotification object:nil];
    [self refresh];
}

- (void)refresh {
    self.statusLabel.text = [RSSubscriptionService shared].isPro ? @"当前会员：Pro" : @"当前会员：Free";
}

- (void)openPaywall {
    [self.navigationController pushViewController:[[RSPaywallViewController alloc] init] animated:YES];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
