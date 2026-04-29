#import <Foundation/Foundation.h>
@interface MembershipManager : NSObject
@property (nonatomic, assign, readonly) BOOL vip;
@property (nonatomic, strong, readonly) NSDate *expireAt;
+ (instancetype)shared;
- (void)subscribeOneYear;
@end
