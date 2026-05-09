#import <SpriteKit/SpriteKit.h>
@interface GameScene : SKScene
@property (nonatomic, copy) void (^gameFinished)(NSInteger score, NSInteger goldGain);
@end
