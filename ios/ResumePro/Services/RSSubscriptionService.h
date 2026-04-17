#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const RSSubscriptionStatusDidChangeNotification;

@interface RSSubscriptionService : NSObject
+ (instancetype)shared;
@property (nonatomic, assign, readonly) BOOL isPro;
- (void)refreshStatus;
- (void)purchaseProWithCompletion:(void(^)(BOOL success, NSString * _Nullable message))completion;
- (void)restorePurchasesWithCompletion:(void(^)(BOOL success, NSString * _Nullable message))completion;
@end

NS_ASSUME_NONNULL_END
