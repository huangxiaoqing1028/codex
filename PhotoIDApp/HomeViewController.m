#import "HomeViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "EditorViewController.h"

@interface HomeViewController () <AVCapturePhotoCaptureDelegate>
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) AVCapturePhotoOutput *photoOutput;
@property (nonatomic, strong) UIButton *captureButton;
@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self buildPremiumUI];
    [self setupCamera];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.session.isRunning) {
        [self.session startRunning];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.session.isRunning) {
        [self.session stopRunning];
    }
}

- (void)buildPremiumUI {
    self.view.backgroundColor = [UIColor blackColor];

    CAGradientLayer *bg = [CAGradientLayer layer];
    bg.colors = @[(id)[UIColor colorWithRed:0.05 green:0.06 blue:0.12 alpha:1].CGColor,
                  (id)[UIColor colorWithRed:0.10 green:0.14 blue:0.24 alpha:1].CGColor];
    bg.frame = self.view.bounds;
    [self.view.layer addSublayer:bg];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectZero];
    title.text = @"AI 证件照";
    title.font = [UIFont systemFontOfSize:32 weight:UIFontWeightBold];
    title.textColor = UIColor.whiteColor;
    [title sizeToFit];
    title.frame = CGRectMake(24, 60, title.bounds.size.width, title.bounds.size.height);
    [self.view addSubview:title];

    UILabel *subtitle = [[UILabel alloc] initWithFrame:CGRectMake(24, 98, 260, 22)];
    subtitle.text = @"标准尺寸 · 智能抠图 · 高级美颜";
    subtitle.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    subtitle.textColor = [UIColor colorWithWhite:1 alpha:0.8];
    [self.view addSubview:subtitle];

    self.captureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.captureButton.frame = CGRectMake((self.view.bounds.size.width - 84) / 2.0,
                                          self.view.bounds.size.height - 110,
                                          84,
                                          84);
    self.captureButton.layer.cornerRadius = 42;
    self.captureButton.backgroundColor = [UIColor colorWithRed:0.23 green:0.51 blue:1 alpha:1];
    [self.captureButton setTitle:@"拍照" forState:UIControlStateNormal];
    self.captureButton.titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    self.captureButton.layer.shadowColor = [UIColor colorWithRed:0.23 green:0.51 blue:1 alpha:1].CGColor;
    self.captureButton.layer.shadowOpacity = 0.5;
    self.captureButton.layer.shadowRadius = 14;
    self.captureButton.layer.shadowOffset = CGSizeMake(0, 8);
    [self.captureButton addTarget:self action:@selector(capturePhoto) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.captureButton];
}

- (void)setupCamera {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {}];
    }

    self.session = [[AVCaptureSession alloc] init];
    self.session.sessionPreset = AVCaptureSessionPresetPhoto;

    AVCaptureDevice *frontCamera = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera
                                                                       mediaType:AVMediaTypeVideo
                                                                        position:AVCaptureDevicePositionFront];
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:frontCamera error:&error];
    if (!error && [self.session canAddInput:input]) {
        [self.session addInput:input];
    }

    self.photoOutput = [[AVCapturePhotoOutput alloc] init];
    if ([self.session canAddOutput:self.photoOutput]) {
        [self.session addOutput:self.photoOutput];
    }

    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.previewLayer.frame = CGRectMake(16, 140, self.view.bounds.size.width - 32, self.view.bounds.size.height - 280);
    self.previewLayer.cornerRadius = 28;
    self.previewLayer.masksToBounds = YES;
    [self.view.layer insertSublayer:self.previewLayer atIndex:1];

    AVCaptureConnection *connection = [self.previewLayer connection];
    if (connection && connection.isVideoMirroringSupported) {
        connection.automaticallyAdjustsVideoMirroring = NO;
        connection.videoMirrored = NO;
    }
}

- (void)capturePhoto {
    AVCapturePhotoSettings *settings = [AVCapturePhotoSettings photoSettings];
    AVCaptureConnection *connection = [self.photoOutput connectionWithMediaType:AVMediaTypeVideo];
    if (connection && connection.isVideoMirroringSupported) {
        connection.automaticallyAdjustsVideoMirroring = NO;
        connection.videoMirrored = NO;
    }
    [self.photoOutput capturePhotoWithSettings:settings delegate:self];
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error {
    if (error) { return; }
    NSData *data = [photo fileDataRepresentation];
    UIImage *image = [UIImage imageWithData:data];
    if (!image) { return; }

    EditorViewController *editor = [[EditorViewController alloc] initWithImage:image];
    [self.navigationController pushViewController:editor animated:YES];
}

@end
