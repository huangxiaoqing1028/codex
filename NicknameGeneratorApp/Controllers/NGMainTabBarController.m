#import "NGMainTabBarController.h"
#import "NGHomeViewController.h"
#import "NGFavoritesViewController.h"
#import "NGHistoryViewController.h"
#import "NGSettingsViewController.h"

@implementation NGMainTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];

    NGHomeViewController *generateVC = [[NGHomeViewController alloc] init];
    UINavigationController *generateNav = [[UINavigationController alloc] initWithRootViewController:generateVC];
    generateNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"生成" image:[UIImage systemImageNamed:@"sparkles"] selectedImage:[UIImage systemImageNamed:@"sparkles"]];

    NGFavoritesViewController *favoritesVC = [[NGFavoritesViewController alloc] init];
    UINavigationController *favoritesNav = [[UINavigationController alloc] initWithRootViewController:favoritesVC];
    favoritesNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"收藏" image:[UIImage systemImageNamed:@"heart"] selectedImage:[UIImage systemImageNamed:@"heart.fill"]];

    NGHistoryViewController *historyVC = [[NGHistoryViewController alloc] init];
    UINavigationController *historyNav = [[UINavigationController alloc] initWithRootViewController:historyVC];
    historyNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"历史" image:[UIImage systemImageNamed:@"clock.arrow.circlepath"] selectedImage:[UIImage systemImageNamed:@"clock.arrow.circlepath"]];

    NGSettingsViewController *settingsVC = [[NGSettingsViewController alloc] init];
    UINavigationController *settingsNav = [[UINavigationController alloc] initWithRootViewController:settingsVC];
    settingsNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"设置" image:[UIImage systemImageNamed:@"gearshape"] selectedImage:[UIImage systemImageNamed:@"gearshape.fill"]];

    self.viewControllers = @[generateNav, favoritesNav, historyNav, settingsNav];
    self.tabBar.tintColor = [UIColor colorWithRed:0.39 green:0.34 blue:0.95 alpha:1.0];
    self.tabBar.unselectedItemTintColor = [UIColor colorWithWhite:0.6 alpha:1.0];
}

@end
