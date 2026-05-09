#import "AchievementViewController.h"
#import "ProgressManager.h"
@implementation AchievementViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor=UIColor.blackColor;
    UIButton *back=[UIButton buttonWithType:UIButtonTypeSystem]; back.translatesAutoresizingMaskIntoConstraints=NO; [back setTitle:@"← 返回" forState:UIControlStateNormal]; [back addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside]; [self.view addSubview:back];
    UILabel *title=[UILabel new]; title.translatesAutoresizingMaskIntoConstraints=NO; title.text=@"成就殿堂"; title.textColor=UIColor.whiteColor; title.font=[UIFont boldSystemFontOfSize:26]; [self.view addSubview:title];
    UITextView *tv=[UITextView new]; tv.translatesAutoresizingMaskIntoConstraints=NO; tv.editable=NO; tv.backgroundColor=UIColor.blackColor; tv.textColor=UIColor.whiteColor;
    NSArray *ach=[ProgressManager shared].achievements.allObjects; tv.text=[NSString stringWithFormat:@"已解锁成就（%lu）\n%@",(unsigned long)ach.count,[ach componentsJoinedByString:@"\n"]?:@"暂无"];
    [self.view addSubview:tv];
    UILayoutGuide *g=self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[[back.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:16],[back.topAnchor constraintEqualToAnchor:g.topAnchor constant:8],[title.centerXAnchor constraintEqualToAnchor:g.centerXAnchor],[title.centerYAnchor constraintEqualToAnchor:back.centerYAnchor],[tv.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:16],[tv.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-16],[tv.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:16],[tv.bottomAnchor constraintEqualToAnchor:g.bottomAnchor constant:-12]]];
}
- (void)goBack { [self.navigationController popViewControllerAnimated:YES]; }
@end
