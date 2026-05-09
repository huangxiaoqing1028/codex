#import "AppDelegate.h"
#import "ScannerViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[ScannerViewController new]];
    navigationController.navigationBar.prefersLargeTitles = YES;
    self.window.rootViewController = navigationController;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
