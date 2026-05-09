#import <Foundation/Foundation.h>
@interface GameConfig : NSObject
@property (nonatomic, assign) float sfxVolume;
@property (nonatomic, assign) float musicVolume;
@property (nonatomic, assign) BOOL hapticsEnabled;
+ (instancetype)shared;
- (void)save;
@end
