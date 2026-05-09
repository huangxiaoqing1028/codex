#import "BossAIController.h"
@implementation BossAIController
- (instancetype)init { if (self=[super init]) { _hpPercent=1.0; _phase=BossPhaseIntro; } return self; }
- (void)updatePhase { if(self.hpPercent < 0.2) self.phase = BossPhaseEnrage; else if(self.hpPercent < 0.6) self.phase = BossPhaseRage; else self.phase = BossPhaseIntro; }
- (NSTimeInterval)nextSkillInterval { [self updatePhase]; return self.phase==BossPhaseEnrage?0.8:(self.phase==BossPhaseRage?1.2:1.8); }
- (NSString *)currentSkill { [self updatePhase]; return self.phase==BossPhaseEnrage?@"天崩地裂":(self.phase==BossPhaseRage?@"烈焰横扫":@"重斩"); }
@end
