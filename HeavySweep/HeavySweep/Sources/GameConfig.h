#import <Foundation/Foundation.h>
@interface GameConfig : NSObject
@property (nonatomic, assign) float sfxVolume;
@property (nonatomic, assign) float musicVolume;
@property (nonatomic, assign) BOOL hapticsEnabled;
@property (nonatomic, assign) NSInteger hapticIntensity; // 0-2
@property (nonatomic, assign) NSInteger frameRate; // 30/60
@property (nonatomic, assign) NSInteger graphicsQuality; // 0 low 1 medium 2 high
@property (nonatomic, assign) BOOL audioMasterEnabled;
+ (instancetype)shared;
- (void)save;
@end
