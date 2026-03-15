#import "IDPhotoProcessor.h"

@implementation IDPhotoProcessor

+ (nullable UIImage *)generateIDPhotoFromImage:(UIImage *)image
                                          spec:(IDPhotoSpec)spec
                               customPixelSize:(CGSize)customPixelSize
                               backgroundColor:(UIColor *)backgroundColor
                                           dpi:(CGFloat)dpi {
    if (!image || dpi <= 0) {
        return nil;
    }

    CGSize outputSize = [self outputPixelSizeForSpec:spec dpi:dpi customPixelSize:customPixelSize];
    if (outputSize.width <= 0 || outputSize.height <= 0) {
        return nil;
    }

    // 1) 等比缩放 + 中心裁剪，保证填满输出区域
    CGSize sourceSize = image.size;
    CGFloat scale = MAX(outputSize.width / sourceSize.width, outputSize.height / sourceSize.height);
    CGSize scaledSize = CGSizeMake(sourceSize.width * scale, sourceSize.height * scale);

    CGFloat drawX = (outputSize.width - scaledSize.width) * 0.5;
    CGFloat drawY = (outputSize.height - scaledSize.height) * 0.5;

    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    format.scale = 1.0; // outputSize 已是像素级，固定 1:1
    format.opaque = YES;

    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:outputSize format:format];
    UIImage *result = [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull rendererContext) {
        CGContextRef ctx = rendererContext.CGContext;

        [backgroundColor setFill];
        CGContextFillRect(ctx, CGRectMake(0, 0, outputSize.width, outputSize.height));

        [image drawInRect:CGRectMake(drawX, drawY, scaledSize.width, scaledSize.height)];
    }];

    return result;
}

+ (CGSize)outputPixelSizeForSpec:(IDPhotoSpec)spec
                             dpi:(CGFloat)dpi
                 customPixelSize:(CGSize)customPixelSize {
    switch (spec) {
        case IDPhotoSpecOneInch:
            return [self millimeterToPixelSize:CGSizeMake(25, 35) dpi:dpi];
        case IDPhotoSpecTwoInch:
            return [self millimeterToPixelSize:CGSizeMake(35, 49) dpi:dpi];
        case IDPhotoSpecSmallTwoInch:
            return [self millimeterToPixelSize:CGSizeMake(35, 45) dpi:dpi];
        case IDPhotoSpecCustom:
            return customPixelSize;
    }
}

+ (CGSize)millimeterToPixelSize:(CGSize)mmSize dpi:(CGFloat)dpi {
    // 1 inch = 25.4 mm
    CGFloat width = round(mmSize.width / 25.4 * dpi);
    CGFloat height = round(mmSize.height / 25.4 * dpi);
    return CGSizeMake(width, height);
}

@end
