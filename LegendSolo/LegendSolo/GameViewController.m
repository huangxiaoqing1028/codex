#import "GameViewController.h"
#import "GameScene.h"

@implementation GameViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blackColor;

    GameScene *scene = [[GameScene alloc] initWithFrame:self.view.bounds];
    scene.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:scene];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20, 56, 250, 36)];
    title.text = @"Legend Solo";
    title.font = [UIFont systemFontOfSize:32 weight:UIFontWeightBlack];
    title.textColor = [UIColor colorWithRed:0.95 green:0.79 blue:0.26 alpha:1];
    [self.view addSubview:title];
}

- (UIStatusBarStyle)preferredStatusBarStyle { return UIStatusBarStyleLightContent; }
@end
