#import "MainViewController.h"
#import <SpriteKit/SpriteKit.h>
#import "GameScene.h"

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    CAGradientLayer *bg = [CAGradientLayer layer];
    bg.frame = self.view.bounds;
    bg.colors = @[(__bridge id)[UIColor colorWithRed:0.08 green:0.07 blue:0.13 alpha:1].CGColor,
                  (__bridge id)[UIColor colorWithRed:0.18 green:0.11 blue:0.09 alpha:1].CGColor];
    [self.view.layer addSublayer:bg];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 120, self.view.bounds.size.width, 60)];
    title.text = @"传奇·单机版";
    title.textAlignment = NSTextAlignmentCenter;
    title.font = [UIFont boldSystemFontOfSize:42];
    title.textColor = [UIColor colorWithRed:0.98 green:0.86 blue:0.58 alpha:1];
    [self.view addSubview:title];

    UIButton *start = [UIButton buttonWithType:UIButtonTypeSystem];
    start.frame = CGRectMake((self.view.bounds.size.width-220)/2, 320, 220, 56);
    start.layer.cornerRadius = 14;
    start.backgroundColor = [UIColor colorWithRed:0.78 green:0.21 blue:0.16 alpha:1];
    [start setTitle:@"进入战场" forState:UIControlStateNormal];
    [start setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    start.titleLabel.font = [UIFont boldSystemFontOfSize:24];
    [start addTarget:self action:@selector(startGame) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:start];
}

- (void)startGame {
    SKView *skView = [[SKView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:skView];
    GameScene *scene = [[GameScene alloc] initWithSize:skView.bounds.size];
    scene.scaleMode = SKSceneScaleModeResizeFill;
    [skView presentScene:scene];
}

@end
