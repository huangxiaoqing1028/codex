#import "OCRService.h"
#import <Vision/Vision.h>

@implementation OCRService

- (void)recognizeTextInImage:(UIImage *)image completion:(OCRServiceCompletion)completion {
    CGImageRef cgImage = image.CGImage;
    if (cgImage == nil) {
        NSError *error = [NSError errorWithDomain:@"OCRService" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"图片格式不支持，请重试。"}];
        completion(nil, error);
        return;
    }

    VNRecognizeTextRequest *request = [[VNRecognizeTextRequest alloc] initWithCompletionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{ completion(nil, error); });
            return;
        }

        NSMutableArray<NSString *> *lines = [NSMutableArray array];
        for (VNRecognizedTextObservation *observation in request.results) {
            VNRecognizedText *candidate = [[observation topCandidates:1] firstObject];
            if (candidate.string.length > 0) {
                [lines addObject:candidate.string];
            }
        }

        NSString *result = [lines componentsJoinedByString:@"\n"];
        dispatch_async(dispatch_get_main_queue(), ^{ completion(result, nil); });
    }];

    request.recognitionLevel = VNRequestTextRecognitionLevelAccurate;
    request.usesLanguageCorrection = YES;
    request.recognitionLanguages = @[@"zh-Hans", @"en-US"];

    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCGImage:cgImage options:@{}];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSError *requestError = nil;
        [handler performRequests:@[request] error:&requestError];
        if (requestError) {
            dispatch_async(dispatch_get_main_queue(), ^{ completion(nil, requestError); });
        }
    });
}

@end
