#import "AppDelegate.h"

#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#define OBF_HAS_AFNETWORKING 1
#else
#define OBF_HAS_AFNETWORKING 0
#endif

static int obf_add(int a, int b) { return a + b; }
static int obf_sub(int a, int b) { return a - b; }
static int obf_xor(int a, int b) { return a ^ b; }
static const char *obf_secret(void) { return "OBF_DEMO_SECRET_LITERAL"; }

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

@interface PodsViewController : UIViewController
@end

@implementation PodsViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Pods";
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20, 120, 340, 30)];
    title.font = [UIFont boldSystemFontOfSize:20];
    title.text = @"CocoaPods + my-clang 兼容性";
    [self.view addSubview:title];

    UILabel *detail = [[UILabel alloc] initWithFrame:CGRectMake(20, 170, 340, 200)];
    detail.numberOfLines = 0;
#if OBF_HAS_AFNETWORKING
    detail.text = @"AFNetworking 已集成。\n说明 Pod target 与主 target 都可使用 my-clang 编译。\n(可在 Build Log 搜索 my-clang / -fpass-plugin 验证)";
#else
    detail.text = @"未检测到 AFNetworking 头文件。\n请在 example/ObfDemo 下执行: pod install\n并使用 ObfDemo.xcworkspace 打开工程。";
#endif
    [self.view addSubview:detail];

#if OBF_HAS_AFNETWORKING
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager GET:@"https://httpbin.org/get" parameters:nil headers:nil progress:nil success:^(__unused NSURLSessionDataTask * _Nonnull task, __unused id  _Nullable responseObject) {
        detail.text = [detail.text stringByAppendingString:@"\n\n网络请求成功（AFNetworking 正常工作）。"];
    } failure:^(__unused NSURLSessionDataTask * _Nullable task, __unused NSError * _Nonnull error) {
        detail.text = [detail.text stringByAppendingString:@"\n\n网络请求失败（但 Pod 编译与链接已验证）。"];
    }];
#endif
}
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];

    ArithmeticViewController *vc1 = [ArithmeticViewController new];
    StringViewController *vc2 = [StringViewController new];
    PodsViewController *vc3 = [PodsViewController new];

    UINavigationController *n1 = [[UINavigationController alloc] initWithRootViewController:vc1];
    UINavigationController *n2 = [[UINavigationController alloc] initWithRootViewController:vc2];
    UINavigationController *n3 = [[UINavigationController alloc] initWithRootViewController:vc3];

    n1.tabBarItem.title = @"算术";
    n2.tabBarItem.title = @"字符串";
    n3.tabBarItem.title = @"Pods";

    UITabBarController *tab = [UITabBarController new];
    tab.viewControllers = @[n1, n2, n3];

    self.window.rootViewController = tab;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
