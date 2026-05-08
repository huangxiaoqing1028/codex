#import "GameScene.h"

@interface GameScene ()
@property(nonatomic,strong) SKSpriteNode *hero;
@property(nonatomic,strong) SKShapeNode *heroHp;
@property(nonatomic,strong) SKLabelNode *scoreLabel;
@property(nonatomic,assign) NSInteger score;
@property(nonatomic,assign) CGFloat heroHealth;
@end

@implementation GameScene

- (void)didMoveToView:(SKView *)view {
    self.backgroundColor = [SKColor colorWithRed:0.07 green:0.05 blue:0.1 alpha:1];
    [self buildUI];
    [self spawnHero];
    [self runAction:[SKAction repeatActionForever:[SKAction sequence:@[[SKAction waitForDuration:1.4],[SKAction performSelector:@selector(spawnMonster) onTarget:self]]]]];
}

- (void)buildUI {
    SKShapeNode *panel = [SKShapeNode shapeNodeWithRect:CGRectMake(10, self.size.height-86, self.size.width-20, 72) cornerRadius:12];
    panel.fillColor = [SKColor colorWithWhite:0 alpha:0.45];
    panel.strokeColor = [SKColor colorWithRed:0.95 green:0.75 blue:0.25 alpha:1];
    panel.lineWidth = 2;
    [self addChild:panel];

    self.scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"AvenirNext-Bold"];
    self.scoreLabel.fontSize = 20;
    self.scoreLabel.fontColor = [SKColor colorWithRed:1 green:0.92 blue:0.72 alpha:1];
    self.scoreLabel.position = CGPointMake(90, self.size.height-48);
    self.scoreLabel.text = @"战功: 0";
    [self addChild:self.scoreLabel];

    self.heroHp = [SKShapeNode shapeNodeWithRect:CGRectMake(210, self.size.height-58, 130, 14) cornerRadius:7];
    self.heroHp.fillColor = [SKColor colorWithRed:0.92 green:0.18 blue:0.24 alpha:1];
    self.heroHp.strokeColor = [SKColor clearColor];
    [self addChild:self.heroHp];
}

- (void)spawnHero {
    self.heroHealth = 100;
    self.hero = [SKSpriteNode spriteNodeWithColor:[SKColor colorWithRed:0.3 green:0.7 blue:1 alpha:1] size:CGSizeMake(34, 34)];
    self.hero.position = CGPointMake(self.size.width/2, self.size.height*0.25);
    [self addChild:self.hero];
}

- (void)spawnMonster {
    SKSpriteNode *m = [SKSpriteNode spriteNodeWithColor:[SKColor colorWithRed:0.9 green:0.25 blue:0.35 alpha:1] size:CGSizeMake(28, 28)];
    CGFloat x = arc4random_uniform((uint32_t)(self.size.width-40))+20;
    m.position = CGPointMake(x, self.size.height+20);
    m.name = @"monster";
    [self addChild:m];

    SKAction *move = [SKAction moveToY:-20 duration:5.0];
    SKAction *hit = [SKAction runBlock:^{
        if (m.parent) {
            [m removeFromParent];
            [self damageHero:8];
        }
    }];
    [m runAction:[SKAction sequence:@[move, hit]]];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = touches.anyObject;
    CGPoint p = [touch locationInNode:self];
    self.hero.position = CGPointMake(MIN(MAX(18,p.x),self.size.width-18), MIN(MAX(18,p.y),self.size.height-18));
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    for (SKNode *n in self.children) {
        if ([n.name isEqualToString:@"monster"] && hypot(n.position.x-self.hero.position.x, n.position.y-self.hero.position.y) < 70) {
            [n removeAllActions];
            [n removeFromParent];
            self.score += 10;
            self.scoreLabel.text = [NSString stringWithFormat:@"战功: %ld", (long)self.score];
            break;
        }
    }
}

- (void)damageHero:(CGFloat)damage {
    self.heroHealth = MAX(0, self.heroHealth-damage);
    CGFloat width = 130 * (self.heroHealth/100.0);
    self.heroHp.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(210, self.size.height-58, width, 14) cornerRadius:7].CGPath;
    if (self.heroHealth <= 0) {
        SKLabelNode *over = [SKLabelNode labelNodeWithFontNamed:@"AvenirNext-Heavy"];
        over.text = @"战斗失败 - 点击重开";
        over.fontSize = 28;
        over.fontColor = [SKColor whiteColor];
        over.position = CGPointMake(self.size.width/2, self.size.height/2);
        over.name = @"restart";
        [self addChild:over];
        self.scene.paused = YES;
    }
}

@end
