#import "GameScene.h"

@interface GameScene ()
@property (nonatomic, strong) UIView *player;
@property (nonatomic, strong) CADisplayLink *link;
@property (nonatomic, assign) CGPoint velocity;
@end

@implementation GameScene
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor colorWithRed:0.08 green:0.10 blue:0.16 alpha:1.0];
        CAGradientLayer *bg = [CAGradientLayer layer];
        bg.frame = self.bounds;
        bg.colors = @[(id)[UIColor colorWithRed:0.09 green:0.12 blue:0.2 alpha:1].CGColor,
                      (id)[UIColor colorWithRed:0.03 green:0.03 blue:0.06 alpha:1].CGColor];
        [self.layer addSublayer:bg];

        self.player = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 48, 48)];
        self.player.center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
        self.player.backgroundColor = [UIColor colorWithRed:0.95 green:0.77 blue:0.24 alpha:1];
        self.player.layer.cornerRadius = 10;
        self.player.layer.shadowColor = UIColor.blackColor.CGColor;
        self.player.layer.shadowOpacity = 0.4;
        self.player.layer.shadowRadius = 8;
        [self addSubview:self.player];

        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
        [self addGestureRecognizer:pan];

        self.link = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick)];
        [self.link addToRunLoop:NSRunLoop.mainRunLoop forMode:NSDefaultRunLoopMode];
    }
    return self;
}

- (void)onPan:(UIPanGestureRecognizer *)pan {
    CGPoint t = [pan translationInView:self];
    self.velocity = CGPointMake(t.x * 0.02, t.y * 0.02);
    if (pan.state == UIGestureRecognizerStateEnded) {
        self.velocity = CGPointZero;
    }
}

- (void)tick {
    CGPoint c = self.player.center;
    c.x += self.velocity.x;
    c.y += self.velocity.y;
    CGFloat inset = 24;
    c.x = MAX(inset, MIN(CGRectGetWidth(self.bounds)-inset, c.x));
    c.y = MAX(inset, MIN(CGRectGetHeight(self.bounds)-inset, c.y));
    self.player.center = c;
}
@end
