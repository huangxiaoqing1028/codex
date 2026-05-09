#import <Foundation/Foundation.h>
typedef NS_ENUM(NSInteger, BossPhase) { BossPhaseIntro, BossPhaseRage, BossPhaseEnrage };
@interface BossAIController : NSObject
@property (nonatomic, assign) CGFloat hpPercent;
@property (nonatomic, assign) BossPhase phase;
- (NSTimeInterval)nextSkillInterval;
- (NSString *)currentSkill;
- (void)updatePhase;
@end
