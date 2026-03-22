#import "SceneDelegate.h"
#import "NGHomeViewController.h"

@implementation SceneDelegate

- (void)scene:(UIScene *)scene
willConnectToSession:(UISceneSession *)session
      options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:[UIWindowScene class]]) {
        return;
    }

    UIWindowScene *windowScene = (UIWindowScene *)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];

    NGHomeViewController *homeVC = [[NGHomeViewController alloc] init];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:homeVC];
    navigationController.navigationBarHidden = YES;

    self.window.rootViewController = navigationController;
    [self.window makeKeyAndVisible];
}

@end
