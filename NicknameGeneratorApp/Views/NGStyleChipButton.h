#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NGStyleChipButton : UIButton

- (instancetype)initWithTitle:(NSString *)title;
- (void)updateSelectedState:(BOOL)selected;

@end

NS_ASSUME_NONNULL_END
