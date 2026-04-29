#import "AccountManager.h"
@implementation AccountManager { BOOL _loggedIn; NSString *_nickname; }
+ (instancetype)shared { static AccountManager*s; static dispatch_once_t once; dispatch_once(&once, ^{s=[AccountManager new];}); return s; }
- (BOOL)loggedIn { return _loggedIn; }
- (NSString *)nickname { return _nickname ?: @"未登录"; }
- (void)loginWithNickname:(NSString *)nickname { _loggedIn=YES; _nickname=nickname.length?nickname:@"用户"; [[NSNotificationCenter defaultCenter] postNotificationName:@"AccountChanged" object:nil]; }
@end
