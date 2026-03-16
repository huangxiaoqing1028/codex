#import "SizePreset.h"

@implementation SizePreset

- (CGFloat)aspectRatio {
    return self.mmSize.width / self.mmSize.height;
}

+ (SizePreset *)presetWithName:(NSString *)name width:(CGFloat)width height:(CGFloat)height {
    SizePreset *p = [[SizePreset alloc] init];
    p.name = name;
    p.mmSize = CGSizeMake(width, height);
    return p;
}

+ (NSArray<SizePreset *> *)commonPresets {
    return @[
        [self presetWithName:@"一寸 (25×35mm)" width:25 height:35],
        [self presetWithName:@"二寸 (35×49mm)" width:35 height:49],
        [self presetWithName:@"小二寸 (35×45mm)" width:35 height:45],
        [self presetWithName:@"身份证 (26×32mm)" width:26 height:32],
        [self presetWithName:@"护照 (33×48mm)" width:33 height:48],
        [self presetWithName:@"签证 (50×50mm)" width:50 height:50],
        [self presetWithName:@"驾驶证 (22×32mm)" width:22 height:32]
    ];
}

+ (UIImage *)cropImage:(UIImage *)image toAspectRatio:(CGFloat)ratio {
    CGSize size = image.size;
    CGFloat sourceRatio = size.width / size.height;
    CGRect cropRect;
    if (sourceRatio > ratio) {
        CGFloat width = size.height * ratio;
        cropRect = CGRectMake((size.width - width) * 0.5, 0, width, size.height);
    } else {
        CGFloat height = size.width / ratio;
        cropRect = CGRectMake(0, (size.height - height) * 0.5, size.width, height);
    }

    CGImageRef cropCG = CGImageCreateWithImageInRect(image.CGImage, cropRect);
    UIImage *result = [UIImage imageWithCGImage:cropCG scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(cropCG);
    return result;
}

@end
