#import "GameScene.h"

@interface GameScene ()
@property (nonatomic, strong) SKLabelNode *scoreLabel;
@property (nonatomic, strong) SKLabelNode *timerLabel;
@property (nonatomic, assign) NSInteger score;
@property (nonatomic, assign) NSTimeInterval timeLeft;
@property (nonatomic, strong) NSMutableArray<SKSpriteNode *> *targets;
@property (nonatomic, strong) SKAction *spawnAction;
@property (nonatomic, strong) SKShapeNode *panel;
@end

@implementation GameScene

- (void)didMoveToView:(SKView *)view {
    self.backgroundColor = [SKColor colorWithRed:0.05 green:0.08 blue:0.16 alpha:1.0];
    self.score = 0;
    self.timeLeft = 60.0;
    self.targets = [NSMutableArray array];

    SKSpriteNode *bg = [SKSpriteNode spriteNodeWithColor:[SKColor colorWithRed:0.10 green:0.16 blue:0.28 alpha:1.0] size:self.size];
    bg.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
    bg.zPosition = -10;
    [self addChild:bg];

    self.panel = [SKShapeNode shapeNodeWithRect:CGRectMake(16, self.size.height - 80, self.size.width - 32, 64) cornerRadius:14];
    self.panel.fillColor = [SKColor colorWithWhite:1 alpha:0.08];
    self.panel.strokeColor = [SKColor colorWithWhite:1 alpha:0.18];
    [self addChild:self.panel];

    self.scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"AvenirNext-Bold"];
    self.scoreLabel.fontSize = 24;
    self.scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
    self.scoreLabel.position = CGPointMake(30, self.size.height - 42);
    [self addChild:self.scoreLabel];

    self.timerLabel = [SKLabelNode labelNodeWithFontNamed:@"AvenirNext-DemiBold"];
    self.timerLabel.fontSize = 24;
    self.timerLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeRight;
    self.timerLabel.position = CGPointMake(self.size.width - 30, self.size.height - 42);
    [self addChild:self.timerLabel];

    [self updateHUD];

    __weak typeof(self) weakSelf = self;
    self.spawnAction = [SKAction runBlock:^{
        [weakSelf spawnTarget];
    }];

    SKAction *delay = [SKAction waitForDuration:0.6 withRange:0.25];
    [self runAction:[SKAction repeatActionForever:[SKAction sequence:@[delay, self.spawnAction]]]];
}

- (void)spawnTarget {
    if (self.timeLeft <= 0) { return; }

    CGFloat radius = 20 + arc4random_uniform(18);
    SKShapeNode *target = [SKShapeNode shapeNodeWithCircleOfRadius:radius];
    target.fillColor = [SKColor colorWithRed:0.94 green:(0.2 + drand48() * 0.4) blue:0.35 alpha:1.0];
    target.strokeColor = [SKColor colorWithWhite:1 alpha:0.6];

    CGFloat x = 30 + arc4random_uniform((uint32_t)(self.size.width - 60));
    CGFloat y = 120 + arc4random_uniform((uint32_t)(self.size.height - 220));
    target.position = CGPointMake(x, y);
    target.name = @"target";

    SKSpriteNode *container = [SKSpriteNode spriteNodeWithTexture:[self.view textureFromNode:target]];
    container.position = target.position;
    container.name = @"target";
    container.zPosition = 5;

    [self.targets addObject:container];
    [self addChild:container];

    SKAction *lifetime = [SKAction sequence:@[
        [SKAction fadeAlphaTo:0.15 duration:1.8],
        [SKAction removeFromParent]
    ]];
    [container runAction:lifetime completion:^{
        [self.targets removeObject:container];
    }];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (self.timeLeft <= 0) {
        [self restartGame];
        return;
    }

    UITouch *touch = touches.anyObject;
    CGPoint location = [touch locationInNode:self];
    SKNode *node = [self nodeAtPoint:location];

    if ([node.name isEqualToString:@"target"]) {
        self.score += 10;
        SKAction *pop = [SKAction sequence:@[
            [SKAction group:@[
                [SKAction scaleTo:1.45 duration:0.08],
                [SKAction fadeOutWithDuration:0.08]
            ]],
            [SKAction removeFromParent]
        ]];
        [node runAction:pop completion:^{
            [self.targets removeObject:(SKSpriteNode *)node];
        }];
    } else {
        self.score = MAX(0, self.score - 3);
    }

    [self updateHUD];
}

- (void)update:(NSTimeInterval)currentTime {
    static NSTimeInterval lastUpdate = 0;
    if (lastUpdate == 0) {
        lastUpdate = currentTime;
        return;
    }

    NSTimeInterval delta = currentTime - lastUpdate;
    lastUpdate = currentTime;

    if (self.timeLeft > 0) {
        self.timeLeft = MAX(0, self.timeLeft - delta);
        [self updateHUD];

        if (self.timeLeft <= 0) {
            [self showGameOver];
        }
    }
}

- (void)showGameOver {
    [self removeAllActions];
    for (SKNode *node in self.targets) {
        [node removeFromParent];
    }
    [self.targets removeAllObjects];

    SKLabelNode *gameOver = [SKLabelNode labelNodeWithFontNamed:@"AvenirNext-Bold"];
    gameOver.text = [NSString stringWithFormat:@"挑战结束：%ld\n点击屏幕再来一局", (long)self.score];
    gameOver.numberOfLines = 2;
    gameOver.fontSize = 28;
    gameOver.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    gameOver.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
    gameOver.name = @"gameOver";
    [self addChild:gameOver];
}

- (void)restartGame {
    SKNode *gameOver = [self childNodeWithName:@"gameOver"];
    [gameOver removeFromParent];

    self.score = 0;
    self.timeLeft = 60;
    [self updateHUD];

    __weak typeof(self) weakSelf = self;
    SKAction *delay = [SKAction waitForDuration:0.6 withRange:0.25];
    self.spawnAction = [SKAction runBlock:^{ [weakSelf spawnTarget]; }];
    [self runAction:[SKAction repeatActionForever:[SKAction sequence:@[delay, self.spawnAction]]]];
}

- (void)updateHUD {
    self.scoreLabel.text = [NSString stringWithFormat:@"得分 %ld", (long)self.score];
    self.timerLabel.text = [NSString stringWithFormat:@"%.0f 秒", ceil(self.timeLeft)];
}

@end
