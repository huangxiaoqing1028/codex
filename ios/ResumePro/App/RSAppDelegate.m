#import "RSAppDelegate.h"
#import "RSRootTabBarController.h"
#import "RSTheme.h"

@implementation RSAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];

    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
    [appearance configureWithOpaqueBackground];
    appearance.backgroundColor = [RSTheme bgSecondary];
    appearance.titleTextAttributes = @{ NSForegroundColorAttributeName:[RSTheme textPrimary] };
    [UINavigationBar appearance].standardAppearance = appearance;
    [UINavigationBar appearance].scrollEdgeAppearance = appearance;
    [UINavigationBar appearance].tintColor = [RSTheme accentGold];

    self.window.rootViewController = [[RSRootTabBarController alloc] init];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
