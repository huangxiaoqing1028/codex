#import "EditorViewController.h"
#import <Vision/Vision.h>
#import <CoreImage/CoreImage.h>
#import "SizePreset.h"

@interface EditorViewController ()
@property (nonatomic, strong) UIImage *sourceImage;
@property (nonatomic, strong) UIImageView *previewView;
@property (nonatomic, strong) UISegmentedControl *bgSegment;
@property (nonatomic, strong) UISlider *whitenSlider;
@property (nonatomic, strong) UISegmentedControl *sizeSegment;
@property (nonatomic, strong) NSArray<SizePreset *> *presets;
@property (nonatomic, strong) CIImage *personMask;
@property (nonatomic, strong) CIContext *context;
@end

@implementation EditorViewController

- (UIImage *)normalizedImage:(UIImage *)image {
    if (image.imageOrientation == UIImageOrientationUp) {
        return image;
    }

    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    format.scale = image.scale;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:image.size format:format];
    UIImage *normalized = [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull rendererContext) {
        [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
    }];
    return normalized;
}

- (CGRect)cropRectForImageSize:(CGSize)size aspectRatio:(CGFloat)ratio {
    CGFloat sourceRatio = size.width / size.height;
    if (sourceRatio > ratio) {
        CGFloat width = size.height * ratio;
        return CGRectMake((size.width - width) * 0.5, 0, width, size.height);
    }

    CGFloat height = size.width / ratio;
    return CGRectMake(0, (size.height - height) * 0.5, size.width, height);
}

- (CIImage *)refinedMaskForSourceExtent:(CGRect)sourceExtent {
    if (!self.personMask) {
        return nil;
    }

    CGFloat scaleX = CGRectGetWidth(sourceExtent) / CGRectGetWidth(self.personMask.extent);
    CGFloat scaleY = CGRectGetHeight(sourceExtent) / CGRectGetHeight(self.personMask.extent);
    CGAffineTransform transform = CGAffineTransformMakeScale(scaleX, scaleY);
    CIImage *mask = [self.personMask imageByApplyingTransform:transform];
    mask = [mask imageByCroppingToRect:sourceExtent];

    CIFilter *contrast = [CIFilter filterWithName:@"CIColorControls"];
    [contrast setValue:mask forKey:kCIInputImageKey];
    [contrast setValue:@0 forKey:kCIInputSaturationKey];
    [contrast setValue:@1.12 forKey:kCIInputContrastKey];
    [contrast setValue:@0 forKey:kCIInputBrightnessKey];
    mask = [contrast outputImage];

    CIFilter *softEdge = [CIFilter filterWithName:@"CIGaussianBlur"];
    [softEdge setValue:mask forKey:kCIInputImageKey];
    [softEdge setValue:@1.0 forKey:kCIInputRadiusKey];
    mask = [[softEdge outputImage] imageByCroppingToRect:sourceExtent];
    return mask;
}

- (instancetype)initWithImage:(UIImage *)image {
    self = [super init];
    if (self) {
        _sourceImage = [self normalizedImage:image];
        _presets = [SizePreset commonPresets];
        _context = [CIContext contextWithOptions:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self buildUI];
    [self generateMaskAndRender];
}

- (void)buildUI {
    self.view.backgroundColor = [UIColor colorWithRed:0.06 green:0.07 blue:0.10 alpha:1];

    self.previewView = [[UIImageView alloc] initWithFrame:CGRectMake(20, 100, self.view.bounds.size.width - 40, self.view.bounds.size.height * 0.52)];
    self.previewView.contentMode = UIViewContentModeScaleAspectFit;
    self.previewView.backgroundColor = UIColor.whiteColor;
    self.previewView.layer.cornerRadius = 22;
    self.previewView.clipsToBounds = YES;
    [self.view addSubview:self.previewView];

    self.bgSegment = [[UISegmentedControl alloc] initWithItems:@[@"白", @"蓝", @"红"]];
    self.bgSegment.frame = CGRectMake(20, CGRectGetMaxY(self.previewView.frame) + 18, self.view.bounds.size.width - 40, 36);
    self.bgSegment.selectedSegmentIndex = 0;
    [self.bgSegment addTarget:self action:@selector(renderComposite) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.bgSegment];

    UILabel *whitenLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(self.bgSegment.frame) + 18, 160, 24)];
    whitenLabel.text = @"美白强度";
    whitenLabel.textColor = UIColor.whiteColor;
    whitenLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [self.view addSubview:whitenLabel];

    self.whitenSlider = [[UISlider alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(whitenLabel.frame) + 8, self.view.bounds.size.width - 40, 30)];
    self.whitenSlider.minimumValue = 0;
    self.whitenSlider.maximumValue = 1;
    self.whitenSlider.value = 0.25;
    [self.whitenSlider addTarget:self action:@selector(renderComposite) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.whitenSlider];

    NSMutableArray *names = [NSMutableArray array];
    for (NSInteger i = 0; i < MIN(4, self.presets.count); i++) {
        [names addObject:self.presets[i].name];
    }
    self.sizeSegment = [[UISegmentedControl alloc] initWithItems:names];
    self.sizeSegment.frame = CGRectMake(20, CGRectGetMaxY(self.whitenSlider.frame) + 16, self.view.bounds.size.width - 40, 36);
    self.sizeSegment.selectedSegmentIndex = 0;
    [self.sizeSegment addTarget:self action:@selector(renderComposite) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.sizeSegment];
}

- (void)generateMaskAndRender {
    CIImage *inputImage = [[CIImage alloc] initWithImage:self.sourceImage];
    VNGeneratePersonSegmentationRequest *request = [[VNGeneratePersonSegmentationRequest alloc] init];
    request.qualityLevel = VNGeneratePersonSegmentationRequestQualityLevelAccurate;
    request.outputPixelFormat = kCVPixelFormatType_OneComponent8;

    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCIImage:inputImage options:@{}];
    NSError *error = nil;
    [handler performRequests:@[request] error:&error];
    if (error || request.results.count == 0) {
        self.personMask = nil;
        [self renderComposite];
        return;
    }

    VNPixelBufferObservation *obs = request.results.firstObject;
    self.personMask = [CIImage imageWithCVPixelBuffer:obs.pixelBuffer];
    [self renderComposite];
}

- (UIColor *)selectedBGColor {
    switch (self.bgSegment.selectedSegmentIndex) {
        case 1: return [UIColor colorWithRed:0.17 green:0.45 blue:0.96 alpha:1];
        case 2: return [UIColor colorWithRed:0.86 green:0.20 blue:0.25 alpha:1];
        default: return UIColor.whiteColor;
    }
}

- (void)renderComposite {
    CIImage *inputCI = [[CIImage alloc] initWithImage:self.sourceImage];
    CGRect sourceExtent = inputCI.extent;

    CIFilter *exposure = [CIFilter filterWithName:@"CIExposureAdjust"];
    [exposure setValue:inputCI forKey:kCIInputImageKey];
    [exposure setValue:@(self.whitenSlider.value * 0.5) forKey:kCIInputEVKey];
    CIImage *whitened = exposure.outputImage;

    SizePreset *preset = self.presets[self.sizeSegment.selectedSegmentIndex];
    CGRect cropRect = [self cropRectForImageSize:sourceExtent.size aspectRatio:preset.aspectRatio];
    CIImage *targetCI = [inputCI imageByCroppingToRect:cropRect];

    CIImage *bg = [CIImage imageWithColor:[[CIColor alloc] initWithColor:[self selectedBGColor]]];
    bg = [bg imageByCroppingToRect:targetCI.extent];

    CIImage *mask = [[self refinedMaskForSourceExtent:sourceExtent] imageByCroppingToRect:cropRect];

    CIImage *foreground = [whitened imageByCroppingToRect:cropRect];
    CIImage *composite = foreground;
    if (mask) {
        CIFilter *blend = [CIFilter filterWithName:@"CIBlendWithMask"
                                     keysAndValues:kCIInputImageKey, foreground,
                                                   kCIInputBackgroundImageKey, bg,
                                                   kCIInputMaskImageKey, mask, nil];
        composite = blend.outputImage;
    }

    CGImageRef cg = [self.context createCGImage:composite fromRect:targetCI.extent];
    self.previewView.image = [UIImage imageWithCGImage:cg];
    CGImageRelease(cg);
}

@end
