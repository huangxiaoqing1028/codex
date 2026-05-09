#import "GameConfig.h"
@implementation GameConfig
+ (instancetype)shared { static GameConfig *c; static dispatch_once_t once; dispatch_once(&once, ^{ c=[GameConfig new]; NSUserDefaults*d=NSUserDefaults.standardUserDefaults; c.sfxVolume=[d objectForKey:@"sfx"]?[d floatForKey:@"sfx"]:0.8; c.musicVolume=[d objectForKey:@"music"]?[d floatForKey:@"music"]:0.7; c.hapticsEnabled=![d objectForKey:@"haptics"]||[d boolForKey:@"haptics"];}); return c;}
- (void)save {NSUserDefaults*d=NSUserDefaults.standardUserDefaults; [d setFloat:self.sfxVolume forKey:@"sfx"]; [d setFloat:self.musicVolume forKey:@"music"]; [d setBool:self.hapticsEnabled forKey:@"haptics"];}
@end
