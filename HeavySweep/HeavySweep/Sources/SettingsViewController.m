#import "SettingsViewController.h"
#import "GameConfig.h"
#import "ProgressManager.h"

@interface SettingsViewController ()
@property (nonatomic, strong) UISlider *sfxSlider;
@property (nonatomic, strong) UISlider *musicSlider;
@property (nonatomic, strong) UISwitch *hapticSwitch;
@property (nonatomic, strong) UISwitch *audioMasterSwitch;
@property (nonatomic, strong) UISegmentedControl *gfxSegment;
@property (nonatomic, strong) UISegmentedControl *fpsSegment;
@property (nonatomic, strong) UISegmentedControl *hapticSegment;
@end

@implementation SettingsViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor=UIColor.systemBackgroundColor;
    UILayoutGuide *g=self.view.safeAreaLayoutGuide;

    UIButton *back=[UIButton buttonWithType:UIButtonTypeSystem]; back.translatesAutoresizingMaskIntoConstraints=NO; [back setTitle:@"← 返回" forState:UIControlStateNormal]; [back addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside]; [self.view addSubview:back];
    UILabel *title=[UILabel new]; title.translatesAutoresizingMaskIntoConstraints=NO; title.text=@"设置中心"; title.font=[UIFont boldSystemFontOfSize:24]; [self.view addSubview:title];

    GameConfig *c=[GameConfig shared];
    UILabel *master=[self mkLabel:@"音频总开关"]; [self.view addSubview:master];
    self.audioMasterSwitch=[UISwitch new]; self.audioMasterSwitch.translatesAutoresizingMaskIntoConstraints=NO; self.audioMasterSwitch.on=c.audioMasterEnabled; [self.audioMasterSwitch addTarget:self action:@selector(onAudioMaster:) forControlEvents:UIControlEventValueChanged]; [self.view addSubview:self.audioMasterSwitch];

    UILabel *sfx=[self mkLabel:@"音效音量"]; [self.view addSubview:sfx];
    self.sfxSlider=[UISlider new]; self.sfxSlider.translatesAutoresizingMaskIntoConstraints=NO; self.sfxSlider.value=c.sfxVolume; [self.sfxSlider addTarget:self action:@selector(onSfxChanged:) forControlEvents:UIControlEventValueChanged]; [self.view addSubview:self.sfxSlider];

    UILabel *music=[self mkLabel:@"音乐音量"]; [self.view addSubview:music];
    self.musicSlider=[UISlider new]; self.musicSlider.translatesAutoresizingMaskIntoConstraints=NO; self.musicSlider.value=c.musicVolume; [self.musicSlider addTarget:self action:@selector(onMusicChanged:) forControlEvents:UIControlEventValueChanged]; [self.view addSubview:self.musicSlider];

    UILabel *gfx=[self mkLabel:@"画质档位"]; [self.view addSubview:gfx];
    self.gfxSegment=[[UISegmentedControl alloc] initWithItems:@[@"低",@"中",@"高"]]; self.gfxSegment.translatesAutoresizingMaskIntoConstraints=NO; self.gfxSegment.selectedSegmentIndex=c.graphicsQuality; [self.gfxSegment addTarget:self action:@selector(onGfxChanged:) forControlEvents:UIControlEventValueChanged]; [self.view addSubview:self.gfxSegment];

    UILabel *fps=[self mkLabel:@"帧率档位"]; [self.view addSubview:fps];
    self.fpsSegment=[[UISegmentedControl alloc] initWithItems:@[@"30 FPS",@"60 FPS"]]; self.fpsSegment.translatesAutoresizingMaskIntoConstraints=NO; self.fpsSegment.selectedSegmentIndex=(c.frameRate==60?1:0); [self.fpsSegment addTarget:self action:@selector(onFpsChanged:) forControlEvents:UIControlEventValueChanged]; [self.view addSubview:self.fpsSegment];

    UILabel *h=[self mkLabel:@"震动开关"]; [self.view addSubview:h];
    self.hapticSwitch=[UISwitch new]; self.hapticSwitch.translatesAutoresizingMaskIntoConstraints=NO; self.hapticSwitch.on=c.hapticsEnabled; [self.hapticSwitch addTarget:self action:@selector(onHapticChanged:) forControlEvents:UIControlEventValueChanged]; [self.view addSubview:self.hapticSwitch];

    UILabel *hi=[self mkLabel:@"触感强度"]; [self.view addSubview:hi];
    self.hapticSegment=[[UISegmentedControl alloc] initWithItems:@[@"弱",@"中",@"强"]]; self.hapticSegment.translatesAutoresizingMaskIntoConstraints=NO; self.hapticSegment.selectedSegmentIndex=c.hapticIntensity; [self.hapticSegment addTarget:self action:@selector(onHapticIntensity:) forControlEvents:UIControlEventValueChanged]; [self.view addSubview:self.hapticSegment];

    UIButton *clear=[UIButton buttonWithType:UIButtonTypeSystem]; clear.translatesAutoresizingMaskIntoConstraints=NO; [clear setTitle:@"清理缓存" forState:UIControlStateNormal]; [clear addTarget:self action:@selector(clearCache) forControlEvents:UIControlEventTouchUpInside]; [self.view addSubview:clear];
    UIButton *reset=[UIButton buttonWithType:UIButtonTypeSystem]; reset.translatesAutoresizingMaskIntoConstraints=NO; [reset setTitle:@"重置本地进度" forState:UIControlStateNormal]; [reset setTitleColor:UIColor.systemRedColor forState:UIControlStateNormal]; [reset addTarget:self action:@selector(resetProgress) forControlEvents:UIControlEventTouchUpInside]; [self.view addSubview:reset];

    [NSLayoutConstraint activateConstraints:@[
      [back.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:16],[back.topAnchor constraintEqualToAnchor:g.topAnchor constant:8],[title.centerXAnchor constraintEqualToAnchor:g.centerXAnchor],[title.centerYAnchor constraintEqualToAnchor:back.centerYAnchor],
      [master.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:24],[master.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:20],[self.audioMasterSwitch.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-24],[self.audioMasterSwitch.centerYAnchor constraintEqualToAnchor:master.centerYAnchor],
      [sfx.leadingAnchor constraintEqualToAnchor:master.leadingAnchor],[sfx.topAnchor constraintEqualToAnchor:master.bottomAnchor constant:16],[self.sfxSlider.leadingAnchor constraintEqualToAnchor:sfx.leadingAnchor],[self.sfxSlider.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-24],[self.sfxSlider.topAnchor constraintEqualToAnchor:sfx.bottomAnchor constant:6],
      [music.leadingAnchor constraintEqualToAnchor:sfx.leadingAnchor],[music.topAnchor constraintEqualToAnchor:self.sfxSlider.bottomAnchor constant:12],[self.musicSlider.leadingAnchor constraintEqualToAnchor:sfx.leadingAnchor],[self.musicSlider.trailingAnchor constraintEqualToAnchor:self.sfxSlider.trailingAnchor],[self.musicSlider.topAnchor constraintEqualToAnchor:music.bottomAnchor constant:6],
      [gfx.leadingAnchor constraintEqualToAnchor:sfx.leadingAnchor],[gfx.topAnchor constraintEqualToAnchor:self.musicSlider.bottomAnchor constant:14],[self.gfxSegment.leadingAnchor constraintEqualToAnchor:sfx.leadingAnchor],[self.gfxSegment.trailingAnchor constraintEqualToAnchor:self.sfxSlider.trailingAnchor],[self.gfxSegment.topAnchor constraintEqualToAnchor:gfx.bottomAnchor constant:6],
      [fps.leadingAnchor constraintEqualToAnchor:sfx.leadingAnchor],[fps.topAnchor constraintEqualToAnchor:self.gfxSegment.bottomAnchor constant:14],[self.fpsSegment.leadingAnchor constraintEqualToAnchor:sfx.leadingAnchor],[self.fpsSegment.trailingAnchor constraintEqualToAnchor:self.sfxSlider.trailingAnchor],[self.fpsSegment.topAnchor constraintEqualToAnchor:fps.bottomAnchor constant:6],
      [h.leadingAnchor constraintEqualToAnchor:sfx.leadingAnchor],[h.topAnchor constraintEqualToAnchor:self.fpsSegment.bottomAnchor constant:14],[self.hapticSwitch.trailingAnchor constraintEqualToAnchor:self.sfxSlider.trailingAnchor],[self.hapticSwitch.centerYAnchor constraintEqualToAnchor:h.centerYAnchor],
      [hi.leadingAnchor constraintEqualToAnchor:sfx.leadingAnchor],[hi.topAnchor constraintEqualToAnchor:h.bottomAnchor constant:10],[self.hapticSegment.leadingAnchor constraintEqualToAnchor:sfx.leadingAnchor],[self.hapticSegment.trailingAnchor constraintEqualToAnchor:self.sfxSlider.trailingAnchor],[self.hapticSegment.topAnchor constraintEqualToAnchor:hi.bottomAnchor constant:6],
      [clear.leadingAnchor constraintEqualToAnchor:sfx.leadingAnchor],[clear.topAnchor constraintEqualToAnchor:self.hapticSegment.bottomAnchor constant:18],[reset.leadingAnchor constraintEqualToAnchor:sfx.leadingAnchor],[reset.topAnchor constraintEqualToAnchor:clear.bottomAnchor constant:10]
    ]];
}
- (UILabel *)mkLabel:(NSString *)text { UILabel *l=[UILabel new]; l.translatesAutoresizingMaskIntoConstraints=NO; l.text=text; l.font=[UIFont systemFontOfSize:15 weight:UIFontWeightSemibold]; return l; }
- (void)goBack { [self.navigationController popViewControllerAnimated:YES]; }
- (void)onAudioMaster:(UISwitch *)s { GameConfig*c=[GameConfig shared]; c.audioMasterEnabled=s.isOn; [c save]; }
- (void)onSfxChanged:(UISlider *)sender { GameConfig *c=[GameConfig shared]; c.sfxVolume=sender.value; [c save]; }
- (void)onMusicChanged:(UISlider *)sender { GameConfig *c=[GameConfig shared]; c.musicVolume=sender.value; [c save]; }
- (void)onGfxChanged:(UISegmentedControl *)s { GameConfig*c=[GameConfig shared]; c.graphicsQuality=s.selectedSegmentIndex; [c save]; }
- (void)onFpsChanged:(UISegmentedControl *)s { GameConfig*c=[GameConfig shared]; c.frameRate=(s.selectedSegmentIndex==1?60:30); [c save]; }
- (void)onHapticChanged:(UISwitch *)sender { GameConfig *c=[GameConfig shared]; c.hapticsEnabled=sender.isOn; [c save]; }
- (void)onHapticIntensity:(UISegmentedControl *)s { GameConfig*c=[GameConfig shared]; c.hapticIntensity=s.selectedSegmentIndex; [c save]; }
- (void)clearCache {
    NSFileManager *fm=[NSFileManager defaultManager];
    NSArray *paths=@[NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask,YES).firstObject,NSTemporaryDirectory()];
    for (NSString *dir in paths) { for (NSString *file in [fm contentsOfDirectoryAtPath:dir error:nil]) { [fm removeItemAtPath:[dir stringByAppendingPathComponent:file] error:nil]; } }
}
- (void)resetProgress { ProgressManager *p=[ProgressManager shared]; p.gold=0; p.bestScore=0; [p.achievements removeAllObjects]; [p save]; }
@end
