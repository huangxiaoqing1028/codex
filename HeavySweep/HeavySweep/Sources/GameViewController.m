#import "GameViewController.h"
#import <SpriteKit/SpriteKit.h>
#import "GameScene.h"
#import "ProgressManager.h"
@implementation GameViewController
- (void)loadView { self.view = [[SKView alloc] initWithFrame:UIScreen.mainScreen.bounds]; }
- (void)viewDidLoad {
    [super viewDidLoad];
    UIButton *back=[UIButton buttonWithType:UIButtonTypeSystem]; back.translatesAutoresizingMaskIntoConstraints=NO; [back setTitle:@"← 返回" forState:UIControlStateNormal]; [back setTitleColor:UIColor.whiteColor forState:UIControlStateNormal]; [back addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside]; [self.view addSubview:back];
    [NSLayoutConstraint activateConstraints:@[[back.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:12],[back.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:6]]];

    SKView *v=(SKView*)self.view; GameScene*s=[[GameScene alloc] initWithSize:v.bounds.size];
    s.gameFinished=^(NSInteger score, NSInteger goldGain){ ProgressManager*p=[ProgressManager shared]; p.gold+=goldGain; p.bestScore=MAX(p.bestScore,score); if(score>=1000)[p.achievements addObject:@"war_god"]; [p save]; [self.navigationController popViewControllerAnimated:YES]; };
    [v presentScene:s];
}
- (void)goBack { [self.navigationController popViewControllerAnimated:YES]; }
@end
