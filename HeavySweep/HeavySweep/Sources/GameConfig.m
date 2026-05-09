#import "GameConfig.h"
@implementation GameConfig
+ (instancetype)shared {
    static GameConfig *c; static dispatch_once_t once;
    dispatch_once(&once, ^{
        c=[GameConfig new]; NSUserDefaults*d=NSUserDefaults.standardUserDefaults;
        c.sfxVolume=[d objectForKey:@"sfx"]?[d floatForKey:@"sfx"]:0.8;
        c.musicVolume=[d objectForKey:@"music"]?[d floatForKey:@"music"]:0.7;
        c.hapticsEnabled=![d objectForKey:@"haptics"]||[d boolForKey:@"haptics"];
        c.hapticIntensity=[d objectForKey:@"haptic_intensity"]?[d integerForKey:@"haptic_intensity"]:1;
        c.frameRate=[d objectForKey:@"frame_rate"]?[d integerForKey:@"frame_rate"]:60;
        c.graphicsQuality=[d objectForKey:@"gfx"]?[d integerForKey:@"gfx"]:2;
        c.audioMasterEnabled=![d objectForKey:@"audio_master"]||[d boolForKey:@"audio_master"];
    });
    return c;
}
- (void)save {
    NSUserDefaults*d=NSUserDefaults.standardUserDefaults;
    [d setFloat:self.sfxVolume forKey:@"sfx"]; [d setFloat:self.musicVolume forKey:@"music"]; [d setBool:self.hapticsEnabled forKey:@"haptics"];
    [d setInteger:self.hapticIntensity forKey:@"haptic_intensity"]; [d setInteger:self.frameRate forKey:@"frame_rate"]; [d setInteger:self.graphicsQuality forKey:@"gfx"]; [d setBool:self.audioMasterEnabled forKey:@"audio_master"];
}
@end
