#import "RSSubscriptionService.h"

NSString * const RSSubscriptionStatusDidChangeNotification = @"RSSubscriptionStatusDidChangeNotification";
static NSString * const kRSProStatusKey = @"kRSProStatusKey";

@interface RSSubscriptionService ()
@property (nonatomic, assign, readwrite) BOOL isPro;
@end

@implementation RSSubscriptionService

+ (instancetype)shared {
    static RSSubscriptionService *svc;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ svc = [[RSSubscriptionService alloc] init]; });
    return svc;
}

- (void)refreshStatus {
    self.isPro = [[NSUserDefaults standardUserDefaults] boolForKey:kRSProStatusKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:RSSubscriptionStatusDidChangeNotification object:nil];
}

- (void)purchaseProWithCompletion:(void(^)(BOOL, NSString * _Nullable))completion {
    // Demo 版：直接置为会员。上架前可接入 StoreKit Products / Transactions。
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kRSProStatusKey];
    [self refreshStatus];
    if (completion) completion(YES, @"购买成功，会员已开通");
}

- (void)restorePurchasesWithCompletion:(void(^)(BOOL, NSString * _Nullable))completion {
    BOOL has = [[NSUserDefaults standardUserDefaults] boolForKey:kRSProStatusKey];
    if (completion) completion(has, has ? @"恢复成功" : @"没有可恢复的订阅");
}

@end
