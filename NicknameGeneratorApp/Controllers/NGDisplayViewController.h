#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NGDisplayViewController : UIViewController

- (instancetype)initWithNickname:(NSString *)nickname NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
