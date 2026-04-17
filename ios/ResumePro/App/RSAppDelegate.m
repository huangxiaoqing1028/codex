#import "RSAppDelegate.h"
#import "RSRootTabBarController.h"

@implementation RSAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = [[RSRootTabBarController alloc] init];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
