#import "RSRootTabBarController.h"
#import "RSHomeViewController.h"
#import "RSMyResumesViewController.h"
#import "RSProfileViewController.h"
#import "RSSubscriptionService.h"
#import "RSTheme.h"

@implementation RSRootTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];

    UINavigationController *home = [[UINavigationController alloc] initWithRootViewController:[[RSHomeViewController alloc] init]];
    home.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"制作" image:[UIImage systemImageNamed:@"square.and.pencil"] selectedImage:[UIImage systemImageNamed:@"square.and.pencil"]];

    UINavigationController *resumes = [[UINavigationController alloc] initWithRootViewController:[[RSMyResumesViewController alloc] init]];
    resumes.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"简历库" image:[UIImage systemImageNamed:@"doc.text"] selectedImage:[UIImage systemImageNamed:@"doc.text.fill"]];

    UINavigationController *profile = [[UINavigationController alloc] initWithRootViewController:[[RSProfileViewController alloc] init]];
    profile.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"会员" image:[UIImage systemImageNamed:@"crown"] selectedImage:[UIImage systemImageNamed:@"crown.fill"]];

    self.viewControllers = @[home, resumes, profile];

    self.tabBar.tintColor = [RSTheme accentGold];
    self.tabBar.barTintColor = [RSTheme bgSecondary];
    self.tabBar.unselectedItemTintColor = [RSTheme textSecondary];

    [[RSSubscriptionService shared] refreshStatus];
}

@end
