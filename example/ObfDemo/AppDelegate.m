#import "AppDelegate.h"

static int obf_add(int a, int b) { return a + b; }
static int obf_sub(int a, int b) { return a - b; }
static int obf_xor(int a, int b) { return a ^ b; }
static const char *obf_secret(void) { return "OBF_DEMO_SECRET_LITERAL"; }

static int obf_mix_flow(int x) {
    int y = obf_add(x, 7);
    if ((obf_xor(y, 3) & 1) == 0) {
        y = obf_sub(y, 2);
    } else {
        y = obf_add(y, 2);
    }
    return obf_xor(y, 0x5A);
}

@interface ArithmeticViewController : UIViewController
@end

@implementation ArithmeticViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Arithmetic";
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    int x = 42;
    int addValue = obf_add(x, 7);
    int subValue = obf_sub(addValue, 5);
    int xorValue = obf_xor(subValue, 0x5A);

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20, 120, 340, 30)];
    title.font = [UIFont boldSystemFontOfSize:20];
    title.text = @"simple-obf 算术变换验证";
    [self.view addSubview:title];

    UILabel *detail = [[UILabel alloc] initWithFrame:CGRectMake(20, 170, 340, 140)];
    detail.numberOfLines = 0;
    detail.text = [NSString stringWithFormat:@"add(42,7)=%d\nsub(add,5)=%d\nxor(sub,0x5A)=%d", addValue, subValue, xorValue];
    [self.view addSubview:detail];
}
@end

@interface StringViewController : UIViewController
@end

@implementation StringViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"String";
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    NSString *secret = [NSString stringWithUTF8String:obf_secret()];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20, 120, 340, 30)];
    title.font = [UIFont boldSystemFontOfSize:20];
    title.text = @"模块级字符串加密验证";
    [self.view addSubview:title];

    UILabel *detail = [[UILabel alloc] initWithFrame:CGRectMake(20, 170, 340, 120)];
    detail.numberOfLines = 0;
    detail.text = [NSString stringWithFormat:@"运行时读取密文解码字符串：\n%@", secret];
    [self.view addSubview:detail];
}
@end

@interface FlowViewController : UIViewController
@end

@implementation FlowViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Flow";
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    int flowValue = obf_mix_flow(11);

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20, 120, 340, 30)];
    title.font = [UIFont boldSystemFontOfSize:20];
    title.text = @"控制流路径验证";
    [self.view addSubview:title];

    UILabel *detail = [[UILabel alloc] initWithFrame:CGRectMake(20, 170, 340, 140)];
    detail.numberOfLines = 0;
    detail.text = [NSString stringWithFormat:@"mix_flow(11)=%d\n可在 IR/Build Log 中对照 basic block 与分支变换。", flowValue];
    [self.view addSubview:detail];
}
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];

    ArithmeticViewController *vc1 = [ArithmeticViewController new];
    StringViewController *vc2 = [StringViewController new];
    FlowViewController *vc3 = [FlowViewController new];

    UINavigationController *n1 = [[UINavigationController alloc] initWithRootViewController:vc1];
    UINavigationController *n2 = [[UINavigationController alloc] initWithRootViewController:vc2];
    UINavigationController *n3 = [[UINavigationController alloc] initWithRootViewController:vc3];

    n1.tabBarItem.title = @"算术";
    n2.tabBarItem.title = @"字符串";
    n3.tabBarItem.title = @"控制流";

    UITabBarController *tab = [UITabBarController new];
    tab.viewControllers = @[n1, n2, n3];

    self.window.rootViewController = tab;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
