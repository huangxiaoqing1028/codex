#import "MembershipManager.h"
@implementation MembershipManager { BOOL _vip; NSDate *_expireAt; }
+ (instancetype)shared { static MembershipManager*m; static dispatch_once_t once; dispatch_once(&once, ^{m=[MembershipManager new];}); return m; }
- (BOOL)vip { return _vip; }
- (NSDate *)expireAt { return _expireAt; }
- (void)subscribeOneYear { _vip=YES; _expireAt=[NSDate dateWithTimeIntervalSinceNow:365*24*3600]; [[NSNotificationCenter defaultCenter] postNotificationName:@"MembershipChanged" object:nil]; }
@end
