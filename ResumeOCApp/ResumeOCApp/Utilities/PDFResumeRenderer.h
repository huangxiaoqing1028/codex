#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class ResumeData;

NS_ASSUME_NONNULL_BEGIN

@interface PDFResumeRenderer : NSObject
+ (nullable NSURL *)renderPDFForResume:(ResumeData *)data;
+ (nullable NSURL *)renderPDFForResume:(ResumeData *)data templateIndex:(NSInteger)templateIndex;
+ (nullable NSURL *)writeHTMLForResume:(ResumeData *)data templateIndex:(NSInteger)templateIndex;
+ (nullable NSURL *)renderPDFFromHTMLAtURL:(NSURL *)htmlURL outputFileName:(NSString *)fileName;
@end

NS_ASSUME_NONNULL_END
