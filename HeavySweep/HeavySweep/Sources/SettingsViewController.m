#import "SettingsViewController.h"
#import "GameConfig.h"
#import "ProgressManager.h"

@interface SettingsViewController ()
@property (nonatomic, strong) UISlider *sfxSlider;
@property (nonatomic, strong) UISlider *musicSlider;
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
    UILabel *sfx=[UILabel new]; sfx.translatesAutoresizingMaskIntoConstraints=NO; sfx.text=@"音效音量"; [self.view addSubview:sfx];
    self.sfxSlider=[UISlider new]; self.sfxSlider.translatesAutoresizingMaskIntoConstraints=NO; self.sfxSlider.value=c.sfxVolume; [self.sfxSlider addTarget:self action:@selector(onSfxChanged:) forControlEvents:UIControlEventValueChanged]; [self.view addSubview:self.sfxSlider];

    UILabel *music=[UILabel new]; music.translatesAutoresizingMaskIntoConstraints=NO; music.text=@"音乐音量"; [self.view addSubview:music];
    self.musicSlider=[UISlider new]; self.musicSlider.translatesAutoresizingMaskIntoConstraints=NO; self.musicSlider.value=c.musicVolume; [self.musicSlider addTarget:self action:@selector(onMusicChanged:) forControlEvents:UIControlEventValueChanged]; [self.view addSubview:self.musicSlider];

    UILabel *h=[UILabel new]; h.translatesAutoresizingMaskIntoConstraints=NO; h.text=@"震动反馈"; [self.view addSubview:h];
    self.hapticSwitch=[UISwitch new]; self.hapticSwitch.translatesAutoresizingMaskIntoConstraints=NO; self.hapticSwitch.on=c.hapticsEnabled; [self.hapticSwitch addTarget:self action:@selector(onHapticChanged:) forControlEvents:UIControlEventValueChanged]; [self.view addSubview:self.hapticSwitch];

    UIButton *reset=[UIButton buttonWithType:UIButtonTypeSystem]; reset.translatesAutoresizingMaskIntoConstraints=NO; [reset setTitle:@"重置本地进度" forState:UIControlStateNormal]; [reset setTitleColor:UIColor.systemRedColor forState:UIControlStateNormal]; [reset addTarget:self action:@selector(resetProgress) forControlEvents:UIControlEventTouchUpInside]; [self.view addSubview:reset];

    UILayoutGuide *g=self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [back.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:16], [back.topAnchor constraintEqualToAnchor:g.topAnchor constant:8],
        [title.centerXAnchor constraintEqualToAnchor:g.centerXAnchor], [title.centerYAnchor constraintEqualToAnchor:back.centerYAnchor],
        [sfx.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:24],[sfx.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:28],
        [self.sfxSlider.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:24], [self.sfxSlider.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-24], [self.sfxSlider.topAnchor constraintEqualToAnchor:sfx.bottomAnchor constant:8],
        [music.leadingAnchor constraintEqualToAnchor:self.sfxSlider.leadingAnchor],[music.topAnchor constraintEqualToAnchor:self.sfxSlider.bottomAnchor constant:18],
        [self.musicSlider.leadingAnchor constraintEqualToAnchor:self.sfxSlider.leadingAnchor],[self.musicSlider.trailingAnchor constraintEqualToAnchor:self.sfxSlider.trailingAnchor],[self.musicSlider.topAnchor constraintEqualToAnchor:music.bottomAnchor constant:8],
        [h.leadingAnchor constraintEqualToAnchor:self.sfxSlider.leadingAnchor],[h.topAnchor constraintEqualToAnchor:self.musicSlider.bottomAnchor constant:22],
        [self.hapticSwitch.leadingAnchor constraintEqualToAnchor:h.trailingAnchor constant:16],[self.hapticSwitch.centerYAnchor constraintEqualToAnchor:h.centerYAnchor],
        [reset.topAnchor constraintEqualToAnchor:h.bottomAnchor constant:30],[reset.leadingAnchor constraintEqualToAnchor:self.sfxSlider.leadingAnchor]
    ]];
}
- (void)goBack { [self.navigationController popViewControllerAnimated:YES]; }
- (void)onSfxChanged:(UISlider *)sender { GameConfig *c=[GameConfig shared]; c.sfxVolume=sender.value; [c save]; }
- (void)onMusicChanged:(UISlider *)sender { GameConfig *c=[GameConfig shared]; c.musicVolume=sender.value; [c save]; }
- (void)onHapticChanged:(UISwitch *)sender { GameConfig *c=[GameConfig shared]; c.hapticsEnabled=sender.isOn; [c save]; }
- (void)resetProgress { ProgressManager *p=[ProgressManager shared]; p.gold=0; p.bestScore=0; [p.achievements removeAllObjects]; [p save]; }
@end
