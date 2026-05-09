#import "ProgressManager.h"
@implementation ProgressManager
+ (instancetype)shared { static ProgressManager *p; static dispatch_once_t once; dispatch_once(&once, ^{ p=[ProgressManager new]; NSUserDefaults*d=NSUserDefaults.standardUserDefaults; p.gold=[d integerForKey:@"gold"]; p.bestScore=[d integerForKey:@"best"]; p.achievements=[NSMutableSet setWithArray:[d arrayForKey:@"ach"]?:@[]]; p.lastOfflineAt=[d objectForKey:@"offline"]?:[NSDate date];}); return p; }
- (NSInteger)collectOfflineReward { NSTimeInterval dt=[[NSDate date] timeIntervalSinceDate:self.lastOfflineAt?:[NSDate date]]; NSInteger reward=MIN(7200,(NSInteger)dt)*2; self.gold+=reward; self.lastOfflineAt=[NSDate date]; [self save]; return reward; }
- (void)save { NSUserDefaults*d=NSUserDefaults.standardUserDefaults; [d setInteger:self.gold forKey:@"gold"]; [d setInteger:self.bestScore forKey:@"best"]; [d setObject:self.achievements.allObjects forKey:@"ach"]; [d setObject:self.lastOfflineAt forKey:@"offline"]; }
@end
