#import <Foundation/Foundation.h>
@interface AccountManager : NSObject
@property (nonatomic, assign, readonly) BOOL loggedIn;
@property (nonatomic, copy, readonly) NSString *nickname;
+ (instancetype)shared;
- (void)loginWithNickname:(NSString *)nickname;
@end
