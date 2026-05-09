#import "MainMenuViewController.h"
#import "GameViewController.h"
#import "SettingsViewController.h"
#import "ProgressManager.h"
@interface MainMenuViewController () @property UILabel *status; @end
@implementation MainMenuViewController
- (void)viewDidLoad { [super viewDidLoad]; self.view.backgroundColor=[UIColor colorWithRed:0.08 green:0.08 blue:0.12 alpha:1]; UILabel*t=[[UILabel alloc]initWithFrame:CGRectMake(20,110,self.view.bounds.size.width-40,44)]; t.text=@"横扫天下-大极品"; t.textColor=UIColor.whiteColor; t.font=[UIFont boldSystemFontOfSize:34]; [self.view addSubview:t]; UIButton*(^mk)(NSString*,SEL,CGFloat)=^UIButton*(NSString*title,SEL sel,CGFloat y){ UIButton*b=[UIButton buttonWithType:UIButtonTypeSystem]; b.frame=CGRectMake(40,y,self.view.bounds.size.width-80,54); b.backgroundColor=[UIColor colorWithRed:0.78 green:0.22 blue:0.18 alpha:1]; [b setTitle:title forState:UIControlStateNormal]; [b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal]; b.layer.cornerRadius=12; [b addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside]; [self.view addSubview:b]; return b;}; mk(@"开始征战",@selector(start),220); mk(@"设置",@selector(openSettings),290);
self.status=[[UILabel alloc]initWithFrame:CGRectMake(20,370,self.view.bounds.size.width-40,120)]; self.status.textColor=UIColor.lightTextColor; self.status.numberOfLines=0; [self.view addSubview:self.status]; }
- (void)viewWillAppear:(BOOL)animated { [super viewWillAppear:animated]; ProgressManager*p=[ProgressManager shared]; NSInteger reward=[p collectOfflineReward]; self.status.text=[NSString stringWithFormat:@"金币:%ld\n历史最高:%ld\n离线收益:+%ld",(long)p.gold,(long)p.bestScore,(long)reward]; }
- (void)start { [self.navigationController pushViewController:[GameViewController new] animated:YES]; }
- (void)openSettings { [self.navigationController pushViewController:[SettingsViewController new] animated:YES]; }
@end
