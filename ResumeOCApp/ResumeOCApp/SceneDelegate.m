#import "SceneDelegate.h"
#import "ViewControllers/ResumeFormViewController.h"

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:[UIWindowScene class]]) {
        return;
    }

    UIWindowScene *windowScene = (UIWindowScene *)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];

    ResumeFormViewController *rootVC = [[ResumeFormViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:rootVC];

    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
}

@end
