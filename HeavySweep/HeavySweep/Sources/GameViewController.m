#import "GameViewController.h"

#import <SpriteKit/SpriteKit.h>

#import "GameScene.h"
#import "ProgressManager.h"

@implementation GameViewController

- (void)loadView {
    self.view = [[SKView alloc] initWithFrame:UIScreen.mainScreen.bounds];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeSystem];
    backButton.translatesAutoresizingMaskIntoConstraints = NO;
    [backButton setTitle:@"← 返回" forState:UIControlStateNormal];
    [backButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backButton];

    [NSLayoutConstraint activateConstraints:@[
        [backButton.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:12],
        [backButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:6]
    ]];

    SKView *skView = (SKView *)self.view;
    GameScene *scene = [[GameScene alloc] initWithSize:skView.bounds.size];
    scene.gameFinished = ^(NSInteger score, NSInteger goldGain) {
        ProgressManager *progress = [ProgressManager shared];
        progress.gold += goldGain;
        progress.bestScore = MAX(progress.bestScore, score);
        if (score >= 1000) {
            [progress.achievements addObject:@"war_god"];
        }
        [progress save];
        [self.navigationController popViewControllerAnimated:YES];
    };
    [skView presentScene:scene];
}

- (void)goBack {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
