#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class ResumeData;

NS_ASSUME_NONNULL_BEGIN

@interface PDFResumeRenderer : NSObject
+ (NSURL *)renderPDFForResume:(ResumeData *)data;
@end

NS_ASSUME_NONNULL_END
