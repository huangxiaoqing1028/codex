#import "SceneDelegate.h"
#import "ViewController.h"

@implementation SceneDelegate

- (void)scene:(UIScene *)scene
willConnectToSession:(UISceneSession *)session
         options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:[UIWindowScene class]]) {
        return;
    }

    UIWindowScene *windowScene = (UIWindowScene *)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];

    ViewController *rootVC = [ViewController new];
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:rootVC];
    navigation.navigationBar.prefersLargeTitles = NO;
    self.window.rootViewController = navigation;
    [self.window makeKeyAndVisible];
}

@end
