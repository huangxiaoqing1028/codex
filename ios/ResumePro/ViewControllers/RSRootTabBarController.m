#import "RSRootTabBarController.h"
#import "RSHomeViewController.h"
#import "RSMyResumesViewController.h"
#import "RSProfileViewController.h"
#import "RSSubscriptionService.h"

@implementation RSRootTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];

    UINavigationController *home = [[UINavigationController alloc] initWithRootViewController:[[RSHomeViewController alloc] init]];
    home.tabBarItem.title = @"创建";

    UINavigationController *resumes = [[UINavigationController alloc] initWithRootViewController:[[RSMyResumesViewController alloc] init]];
    resumes.tabBarItem.title = @"我的简历";

    UINavigationController *profile = [[UINavigationController alloc] initWithRootViewController:[[RSProfileViewController alloc] init]];
    profile.tabBarItem.title = @"会员";

    self.viewControllers = @[home, resumes, profile];
    self.tabBar.tintColor = [UIColor colorWithRed:0.78 green:0.64 blue:0.42 alpha:1.0];

    [[RSSubscriptionService shared] refreshStatus];
}

@end
