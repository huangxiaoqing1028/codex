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
static int obf_and(int a, int b) { return a & b; }
static int obf_or(int a, int b) { return a | b; }
static int obf_mul_pow2(int a) { return a * 8; }
static const char *obf_secret(void) { return "OBF_DEMO_SECRET_LITERAL"; }
static int obf_callee_a(int x) { return x + 11; }
static int obf_callee_b(int x) { return x - 3; }
static int obf_branchy_mix(int seed) {
    int v = seed;
    if ((v & 1) == 0) {
        v = obf_callee_a(v);
    } else {
        v = obf_callee_b(v);
    }

    for (int i = 0; i < 3; ++i) {
        if ((v ^ i) & 1) {
            v = obf_add(v, i + 1);
        } else {
            v = obf_sub(v, i + 2);
        }
    }
    return v;
}

typedef struct {
    int addValue;
    int subValue;
    int xorValue;
    int andValue;
    int orValue;
    int mulPow2Value;
    int branchyValue;
} ObfPassProbeResult;

static ObfPassProbeResult obf_run_probe_suite(int x) {
    ObfPassProbeResult R;
    R.addValue = obf_add(x, 7);
    R.subValue = obf_sub(R.addValue, 5);
    R.xorValue = obf_xor(R.subValue, 0x5A);
    R.andValue = obf_and(R.xorValue, 0x3F);
    R.orValue = obf_or(R.andValue, 0x120);
    R.mulPow2Value = obf_mul_pow2(R.orValue);
    R.branchyValue = obf_branchy_mix(R.mulPow2Value);
    return R;
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

@interface PassHitViewController : UIViewController
@end

@implementation PassHitViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"PassHit";
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    ObfPassProbeResult R = obf_run_probe_suite(42);

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20, 90, 340, 30)];
    title.font = [UIFont boldSystemFontOfSize:20];
    title.text = @"命中规则探针（C 函数）";
    [self.view addSubview:title];

    UILabel *detail = [[UILabel alloc] initWithFrame:CGRectMake(20, 130, 340, 280)];
    detail.numberOfLines = 0;
    detail.font = [UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightRegular];
    detail.text =
    [NSString stringWithFormat:
     @"add=%d\nsub=%d\nxor=%d\nand=%d\nor=%d\nmul_pow2=%d\nbranchy=%d\n\n"
     "建议在导出的 IR 里检索：\n"
     "obf.mba.* / obf.const.* / obf.mul2shl / obf.split / obf.bogus / obf.callee",
     R.addValue, R.subValue, R.xorValue, R.andValue, R.orValue, R.mulPow2Value, R.branchyValue];
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
    title.text = @"CocoaPods 兼容性验证";
    [self.view addSubview:title];

    UILabel *detail = [[UILabel alloc] initWithFrame:CGRectMake(20, 170, 340, 200)];
    detail.numberOfLines = 0;
#if OBF_HAS_AFNETWORKING
    detail.text = @"AFNetworking 已集成。\nPods 目标默认使用系统 clang；\n主 target 继续使用 ObfToolchain.xcconfig 中的 my-clang。";
#else
    detail.text = @"未检测到 AFNetworking 头文件。\n请在 example/ObfDemo 下执行: pod install\n并使用 ObfDemo.xcworkspace 打开工程。";
#endif
    [self.view addSubview:detail];

#if OBF_HAS_AFNETWORKING
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager GET:@"https://httpbin.org/get" parameters:nil headers:nil progress:nil success:^(__unused NSURLSessionDataTask * _Nonnull task, __unused id  _Nullable responseObject) {
        detail.text = [detail.text stringByAppendingString:@"\n\n网络请求成功（Pods 第三方库运行正常）。"];
    } failure:^(__unused NSURLSessionDataTask * _Nullable task, __unused NSError * _Nonnull error) {
        detail.text = [detail.text stringByAppendingString:@"\n\n网络请求失败（但 Pods 集成与链接已验证）。"];
    }];
#endif
}
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];

    ArithmeticViewController *vc1 = [ArithmeticViewController new];
    StringViewController *vc2 = [StringViewController new];
    PassHitViewController *vc3 = [PassHitViewController new];
    PodsViewController *vc4 = [PodsViewController new];

    UINavigationController *n1 = [[UINavigationController alloc] initWithRootViewController:vc1];
    UINavigationController *n2 = [[UINavigationController alloc] initWithRootViewController:vc2];
    UINavigationController *n3 = [[UINavigationController alloc] initWithRootViewController:vc3];
    UINavigationController *n4 = [[UINavigationController alloc] initWithRootViewController:vc4];

    n1.tabBarItem.title = @"算术";
    n2.tabBarItem.title = @"字符串";
    n3.tabBarItem.title = @"命中探针";
    n4.tabBarItem.title = @"Pods";

    UITabBarController *tab = [UITabBarController new];
    tab.viewControllers = @[n1, n2, n3, n4];

    self.window.rootViewController = tab;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
