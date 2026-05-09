#import "GameViewController.h"
#import <SpriteKit/SpriteKit.h>
#import "GameScene.h"
#import "ProgressManager.h"
@implementation GameViewController
- (void)loadView { self.view = [[SKView alloc] initWithFrame:UIScreen.mainScreen.bounds]; }
- (void)viewDidLoad { [super viewDidLoad]; SKView *v=(SKView*)self.view; GameScene*s=[[GameScene alloc] initWithSize:v.bounds.size]; __weak typeof(self) w=self; s.gameFinished=^(NSInteger score, NSInteger goldGain){ ProgressManager*p=[ProgressManager shared]; p.gold+=goldGain; p.bestScore=MAX(p.bestScore,score); if(score>=1000)[p.achievements addObject:@"war_god"]; [p save]; [w.navigationController popViewControllerAnimated:YES]; }; [v presentScene:s]; }
@end
