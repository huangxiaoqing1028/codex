#import "RSPDFExportService.h"
#import <UIKit/UIKit.h>
#import "RSResumeRenderView.h"
#import "RSTemplateService.h"
#import "RSResume.h"
#import "RSTemplate.h"

@implementation RSPDFExportService

- (NSURL * _Nullable)exportResume:(RSResume *)resume error:(NSError **)error {
    CGRect pageRect = CGRectMake(0, 0, 595, 842); // A4 @72dpi
    RSTemplate *templateModel = [[RSTemplateService shared] templateById:resume.templateId];

    RSResumeRenderView *renderView = [[RSResumeRenderView alloc] initWithFrame:pageRect];
    [renderView configureWithResume:resume template:templateModel];
    [renderView layoutIfNeeded];

    UIGraphicsPDFRenderer *renderer = [[UIGraphicsPDFRenderer alloc] initWithBounds:pageRect];
    NSData *pdfData = [renderer PDFDataWithActions:^(UIGraphicsPDFRendererContext * _Nonnull context) {
        [context beginPage];
        [renderView.layer renderInContext:context.CGContext];
    }];

    NSString *filename = [NSString stringWithFormat:@"Resume-%@.pdf", resume.fullName.length ? resume.fullName : @"Candidate"];
    NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject URLByAppendingPathComponent:filename];

    BOOL ok = [pdfData writeToURL:url options:NSDataWritingAtomic error:error];
    return ok ? url : nil;
}

@end
