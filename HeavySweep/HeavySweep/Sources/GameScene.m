#import "GameScene.h"

@interface GameScene ()
@property NSInteger score;
@property NSTimeInterval timeLeft;
@property NSTimeInterval lastUpdateTime;
@property SKLabelNode *scoreLabel;
@property SKLabelNode *timerLabel;
@end

@implementation GameScene
- (void)didMoveToView:(SKView *)view {
    self.backgroundColor=[SKColor blackColor];
    self.timeLeft=90;
    self.lastUpdateTime=0;

    CGFloat topInset = 0;
    if (@available(iOS 11.0, *)) { topInset = view.safeAreaInsets.top; }
    CGFloat hudY = self.size.height - MAX(56, topInset + 28);

    self.scoreLabel=[SKLabelNode labelNodeWithFontNamed:@"AvenirNext-Bold"];
    self.scoreLabel.fontSize=22;
    self.scoreLabel.horizontalAlignmentMode=SKLabelHorizontalAlignmentModeLeft;
    self.scoreLabel.position=CGPointMake(20, hudY);
    [self addChild:self.scoreLabel];

    self.timerLabel=[SKLabelNode labelNodeWithFontNamed:@"AvenirNext-Bold"];
    self.timerLabel.fontSize=22;
    self.timerLabel.horizontalAlignmentMode=SKLabelHorizontalAlignmentModeRight;
    self.timerLabel.position=CGPointMake(self.size.width-20, hudY);
    [self addChild:self.timerLabel];

    [self spawn];
    [self refresh];
}

- (void)spawn {
    if(self.timeLeft<=0)return;
    SKShapeNode*t=[SKShapeNode shapeNodeWithCircleOfRadius:18+arc4random_uniform(22)];
    t.fillColor=[SKColor colorWithRed:0.8 green:0.2+drand48()*0.4 blue:0.2 alpha:1];
    t.position=CGPointMake(40+arc4random_uniform((uint32_t)MAX(1,self.size.width-80)),160+arc4random_uniform((uint32_t)MAX(1,self.size.height-240)));
    t.name=@"mob";
    [self addChild:t];
    [t runAction:[SKAction sequence:@[[SKAction waitForDuration:1.6],[SKAction removeFromParent]]]];
    [self runAction:[SKAction sequence:@[[SKAction waitForDuration:0.28],[SKAction runBlock:^{[self spawn];}]]]];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    CGPoint p=[[touches anyObject] locationInNode:self];
    SKNode*n=[self nodeAtPoint:p];
    if([n.name isEqualToString:@"mob"]){self.score+=15; [n removeFromParent];}
    else self.score=MAX(0,self.score-4);
    [self refresh];
}

- (void)update:(NSTimeInterval)currentTime {
    if(self.lastUpdateTime==0){ self.lastUpdateTime=currentTime; return; }
    NSTimeInterval dt = currentTime-self.lastUpdateTime;
    self.lastUpdateTime=currentTime;

    if(self.timeLeft>0){
        self.timeLeft = MAX(0,self.timeLeft-dt);
        if(self.timeLeft<=0){
            [self removeAllActions];
            NSInteger gold=80+self.score/3;
            if(self.gameFinished) self.gameFinished(self.score,gold);
        }
        [self refresh];
    }
}

- (void)refresh {
    self.scoreLabel.text=[NSString stringWithFormat:@"战力:%ld",(long)self.score];
    self.timerLabel.text=[NSString stringWithFormat:@"倒计时:%02.0f",ceil(self.timeLeft)];
}
@end
