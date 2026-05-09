#import <UIKit/UIKit.h>
@interface GuideOverlayView : UIView
- (void)showInView:(UIView *)view text:(NSString *)text onDismiss:(dispatch_block_t)onDismiss;
@end
