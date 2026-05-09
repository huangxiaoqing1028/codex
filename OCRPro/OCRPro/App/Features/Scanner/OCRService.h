#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^OCRServiceCompletion)(NSString * _Nullable text, NSError * _Nullable error);

@interface OCRService : NSObject
- (void)recognizeTextInImage:(UIImage *)image completion:(OCRServiceCompletion)completion;
@end

NS_ASSUME_NONNULL_END
