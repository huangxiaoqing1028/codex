#import "MainTabBarController.h"
#import "HomeViewController.h"
#import "ResumeListViewController.h"
#import "DiscoverViewController.h"
#import "ProfileViewController.h"

@implementation MainTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.viewControllers = @[
        [self wrappedController:[HomeViewController new] title:@"首页" image:@"house"],
        [self wrappedController:[ResumeListViewController new] title:@"简历" image:@"doc.text"],
        [self wrappedController:[DiscoverViewController new] title:@"发现" image:@"sparkles"],
        [self wrappedController:[ProfileViewController new] title:@"我的" image:@"person"]
    ];
    self.tabBar.tintColor = [UIColor colorWithRed:0.36 green:0.38 blue:0.96 alpha:1.0];
}

- (UINavigationController *)wrappedController:(UIViewController *)controller title:(NSString *)title image:(NSString *)image {
    controller.title = title;
    controller.tabBarItem = [[UITabBarItem alloc] initWithTitle:title image:[UIImage systemImageNamed:image] selectedImage:nil];
    return [[UINavigationController alloc] initWithRootViewController:controller];
}

@end
