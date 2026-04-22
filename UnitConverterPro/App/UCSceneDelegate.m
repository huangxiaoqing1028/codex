#import "UCSceneDelegate.h"
#import "UCConverterViewController.h"

@implementation UCSceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:[UIWindowScene class]]) {
        return;
    }

    UIWindowScene *windowScene = (UIWindowScene *)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];

    UCConverterViewController *converterVC = [[UCConverterViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:converterVC];

    nav.navigationBar.prefersLargeTitles = YES;
    nav.navigationBar.tintColor = [UIColor colorWithRed:0.15 green:0.32 blue:0.98 alpha:1.0];

    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
}

@end
