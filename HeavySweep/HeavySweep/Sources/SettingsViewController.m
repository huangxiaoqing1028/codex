#import "SettingsViewController.h"
#import "GameConfig.h"

@interface SettingsViewController ()
@property (nonatomic, strong) UISlider *sfxSlider;
@property (nonatomic, strong) UISwitch *hapticSwitch;
@end

@implementation SettingsViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor=UIColor.systemBackgroundColor;
    self.title=@"设置";
    GameConfig *c=[GameConfig shared];

    self.sfxSlider=[[UISlider alloc]initWithFrame:CGRectMake(30,140,self.view.bounds.size.width-60,30)];
    self.sfxSlider.value=c.sfxVolume;
    [self.sfxSlider addTarget:self action:@selector(onSfxChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.sfxSlider];

    self.hapticSwitch=[[UISwitch alloc]initWithFrame:CGRectMake(30,200,80,40)];
    self.hapticSwitch.on=c.hapticsEnabled;
    [self.hapticSwitch addTarget:self action:@selector(onHapticChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.hapticSwitch];

    UITextView *privacy=[[UITextView alloc]initWithFrame:CGRectMake(20,270,self.view.bounds.size.width-40,300)];
    privacy.editable=NO;
    privacy.text=@"隐私说明：本游戏为单机，不收集个人数据，不接入广告追踪，不请求通讯录/定位权限。";
    [self.view addSubview:privacy];
}

- (void)onSfxChanged:(UISlider *)sender { GameConfig *c=[GameConfig shared]; c.sfxVolume=sender.value; [c save]; }
- (void)onHapticChanged:(UISwitch *)sender { GameConfig *c=[GameConfig shared]; c.hapticsEnabled=sender.isOn; [c save]; }
@end
