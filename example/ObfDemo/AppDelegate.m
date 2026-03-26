#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];

    UIViewController *vc = [UIViewController new];
    vc.view.backgroundColor = [UIColor systemBackgroundColor];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(40, 200, 300, 40)];
    label.text = @"SimpleObf iOS Demo";
    [vc.view addSubview:label];

    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
