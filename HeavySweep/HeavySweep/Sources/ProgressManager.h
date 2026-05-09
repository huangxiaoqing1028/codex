#import <Foundation/Foundation.h>
@interface ProgressManager : NSObject
@property (nonatomic, assign) NSInteger gold;
@property (nonatomic, assign) NSInteger bestScore;
@property (nonatomic, strong) NSMutableSet<NSString *> *achievements;
@property (nonatomic, strong) NSDate *lastOfflineAt;
+ (instancetype)shared;
- (void)save;
- (NSInteger)collectOfflineReward;
@end
