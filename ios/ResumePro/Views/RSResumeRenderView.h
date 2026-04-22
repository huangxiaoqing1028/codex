#import <UIKit/UIKit.h>
@class RSResume;
@class RSTemplate;

NS_ASSUME_NONNULL_BEGIN

@interface RSResumeRenderView : UIView
- (void)configureWithResume:(RSResume *)resume template:(RSTemplate *)templateModel;
@end

NS_ASSUME_NONNULL_END
