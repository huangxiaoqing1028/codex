#import <UIKit/UIKit.h>
#import "OCBBaseConverter.h"

@interface OCBResultViewController : UIViewController

- (instancetype)initWithInput:(NSString *)input
                       output:(NSString *)output
                       source:(OCBBaseType)source
                       target:(OCBBaseType)target;

@end
