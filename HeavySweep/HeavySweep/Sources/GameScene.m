#import "GameScene.h"
@interface GameScene ()
@property NSInteger score; @property NSTimeInterval timeLeft; @property SKLabelNode *hud;
@end
@implementation GameScene
- (void)didMoveToView:(SKView *)view { self.backgroundColor=[SKColor blackColor]; self.timeLeft=90; self.hud=[SKLabelNode labelNodeWithFontNamed:@"AvenirNext-Bold"]; self.hud.position=CGPointMake(self.size.width/2,self.size.height-60); [self addChild:self.hud]; [self spawn]; [self refresh]; }
- (void)spawn { if(self.timeLeft<=0)return; SKShapeNode*t=[SKShapeNode shapeNodeWithCircleOfRadius:18+arc4random_uniform(22)]; t.fillColor=[SKColor colorWithRed:0.8 green:0.2+drand48()*0.4 blue:0.2 alpha:1]; t.position=CGPointMake(40+arc4random_uniform(self.size.width-80),160+arc4random_uniform(self.size.height-240)); t.name=@"mob"; [self addChild:t]; [t runAction:[SKAction sequence:@[[SKAction waitForDuration:1.6],[SKAction removeFromParent]]]]; [self runAction:[SKAction sequence:@[[SKAction waitForDuration:0.28],[SKAction runBlock:^{[self spawn];}]]]]; }
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event { CGPoint p=[[touches anyObject] locationInNode:self]; SKNode*n=[self nodeAtPoint:p]; if([n.name isEqualToString:@"mob"]){self.score+=15; [n removeFromParent];} else self.score=MAX(0,self.score-4); [self refresh]; }
- (void)update:(NSTimeInterval)currentTime { static NSTimeInterval last=0; if(!last){last=currentTime;return;} self.timeLeft-=currentTime-last; last=currentTime; if(self.timeLeft<=0){ [self removeAllActions]; NSInteger gold=80+self.score/3; if(self.gameFinished) self.gameFinished(self.score,gold);} [self refresh]; }
- (void)refresh { self.hud.text=[NSString stringWithFormat:@"战力:%ld  倒计时:%02.0f",(long)self.score,MAX(0,ceil(self.timeLeft))]; }
@end
