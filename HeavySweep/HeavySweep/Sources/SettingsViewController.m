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

    UIButton *back=[UIButton buttonWithType:UIButtonTypeSystem];
    back.translatesAutoresizingMaskIntoConstraints=NO;
    [back setTitle:@"← 返回" forState:UIControlStateNormal];
    [back addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:back];

    UILabel *title=[UILabel new]; title.translatesAutoresizingMaskIntoConstraints=NO; title.text=@"设置"; title.font=[UIFont boldSystemFontOfSize:24]; [self.view addSubview:title];

    GameConfig *c=[GameConfig shared];
    self.sfxSlider=[UISlider new]; self.sfxSlider.translatesAutoresizingMaskIntoConstraints=NO; self.sfxSlider.value=c.sfxVolume;
    [self.sfxSlider addTarget:self action:@selector(onSfxChanged:) forControlEvents:UIControlEventValueChanged]; [self.view addSubview:self.sfxSlider];

    self.hapticSwitch=[UISwitch new]; self.hapticSwitch.translatesAutoresizingMaskIntoConstraints=NO; self.hapticSwitch.on=c.hapticsEnabled;
    [self.hapticSwitch addTarget:self action:@selector(onHapticChanged:) forControlEvents:UIControlEventValueChanged]; [self.view addSubview:self.hapticSwitch];

    UITextView *privacy=[UITextView new]; privacy.translatesAutoresizingMaskIntoConstraints=NO; privacy.editable=NO; privacy.font=[UIFont systemFontOfSize:16];
    privacy.text=@"隐私说明：本游戏为单机，不收集个人数据，不接入广告追踪，不请求通讯录/定位权限。"; [self.view addSubview:privacy];

    UILayoutGuide *g=self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [back.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:16], [back.topAnchor constraintEqualToAnchor:g.topAnchor constant:8],
        [title.centerXAnchor constraintEqualToAnchor:g.centerXAnchor], [title.centerYAnchor constraintEqualToAnchor:back.centerYAnchor],
        [self.sfxSlider.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:24], [self.sfxSlider.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-24], [self.sfxSlider.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:36],
        [self.hapticSwitch.leadingAnchor constraintEqualToAnchor:self.sfxSlider.leadingAnchor], [self.hapticSwitch.topAnchor constraintEqualToAnchor:self.sfxSlider.bottomAnchor constant:26],
        [privacy.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:20], [privacy.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-20], [privacy.topAnchor constraintEqualToAnchor:self.hapticSwitch.bottomAnchor constant:24], [privacy.bottomAnchor constraintLessThanOrEqualToAnchor:g.bottomAnchor constant:-20]
    ]];
}
- (void)goBack { [self.navigationController popViewControllerAnimated:YES]; }
- (void)onSfxChanged:(UISlider *)sender { GameConfig *c=[GameConfig shared]; c.sfxVolume=sender.value; [c save]; }
- (void)onHapticChanged:(UISwitch *)sender { GameConfig *c=[GameConfig shared]; c.hapticsEnabled=sender.isOn; [c save]; }
@end
