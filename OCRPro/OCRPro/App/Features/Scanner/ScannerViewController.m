#import "ScannerViewController.h"
#import "OCRService.h"
#import "ResultViewController.h"

@interface ScannerViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, strong) UIImageView *previewImageView;
@property (nonatomic, strong) UIButton *cameraButton;
@property (nonatomic, strong) UIButton *galleryButton;
@property (nonatomic, strong) UIButton *recognizeButton;
@property (nonatomic, strong) UIActivityIndicatorView *indicator;
@property (nonatomic, strong) OCRService *ocrService;
@end

@implementation ScannerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"OCR Pro";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.ocrService = [OCRService new];

    UILabel *subtitle = [[UILabel alloc] init];
    subtitle.translatesAutoresizingMaskIntoConstraints = NO;
    subtitle.text = @"智能识别票据、文档、海报等多场景文字";
    subtitle.textColor = [UIColor secondaryLabelColor];
    subtitle.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];

    self.previewImageView = [[UIImageView alloc] init];
    self.previewImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.previewImageView.backgroundColor = [UIColor secondarySystemBackgroundColor];
    self.previewImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.previewImageView.layer.cornerRadius = 20;
    self.previewImageView.clipsToBounds = YES;

    self.cameraButton = [self primaryButtonWithTitle:@"拍照识别" action:@selector(openCamera)];
    self.galleryButton = [self primaryButtonWithTitle:@"相册导入" action:@selector(openGallery)];
    self.recognizeButton = [self accentButtonWithTitle:@"开始识别" action:@selector(recognizeText)];

    self.indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.indicator.translatesAutoresizingMaskIntoConstraints = NO;
    self.indicator.hidesWhenStopped = YES;

    UIStackView *buttonStack = [[UIStackView alloc] initWithArrangedSubviews:@[self.cameraButton, self.galleryButton, self.recognizeButton]];
    buttonStack.translatesAutoresizingMaskIntoConstraints = NO;
    buttonStack.axis = UILayoutConstraintAxisVertical;
    buttonStack.spacing = 12;

    [self.view addSubview:subtitle];
    [self.view addSubview:self.previewImageView];
    [self.view addSubview:buttonStack];
    [self.view addSubview:self.indicator];

    [NSLayoutConstraint activateConstraints:@[
        [subtitle.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8],
        [subtitle.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [subtitle.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],

        [self.previewImageView.topAnchor constraintEqualToAnchor:subtitle.bottomAnchor constant:16],
        [self.previewImageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.previewImageView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [self.previewImageView.heightAnchor constraintEqualToAnchor:self.view.heightAnchor multiplier:0.45],

        [buttonStack.topAnchor constraintEqualToAnchor:self.previewImageView.bottomAnchor constant:18],
        [buttonStack.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [buttonStack.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],

        [self.indicator.centerXAnchor constraintEqualToAnchor:self.previewImageView.centerXAnchor],
        [self.indicator.centerYAnchor constraintEqualToAnchor:self.previewImageView.centerYAnchor]
    ]];
}

- (UIButton *)primaryButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    button.backgroundColor = [UIColor tertiarySystemBackgroundColor];
    [button setTitleColor:[UIColor labelColor] forState:UIControlStateNormal];
    button.layer.cornerRadius = 14;
    button.contentEdgeInsets = UIEdgeInsetsMake(14, 16, 14, 16);
    [button.heightAnchor constraintEqualToConstant:52].active = YES;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (UIButton *)accentButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [self primaryButtonWithTitle:title action:action];
    button.backgroundColor = [UIColor systemBlueColor];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    return button;
}

- (void)openCamera {
    [self presentPickerForSource:UIImagePickerControllerSourceTypeCamera];
}

- (void)openGallery {
    [self presentPickerForSource:UIImagePickerControllerSourceTypePhotoLibrary];
}

- (void)presentPickerForSource:(UIImagePickerControllerSourceType)source {
    if (![UIImagePickerController isSourceTypeAvailable:source]) { return; }
    UIImagePickerController *picker = [UIImagePickerController new];
    picker.sourceType = source;
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)recognizeText {
    if (!self.previewImageView.image) {
        [self showHint:@"请先拍照或选择图片"]; return;
    }
    self.recognizeButton.enabled = NO;
    [self.indicator startAnimating];
    __weak typeof(self) weakSelf = self;
    [self.ocrService recognizeTextInImage:self.previewImageView.image completion:^(NSString * _Nullable text, NSError * _Nullable error) {
        __strong typeof(weakSelf) self = weakSelf;
        self.recognizeButton.enabled = YES;
        [self.indicator stopAnimating];
        if (error) {
            [self showHint:error.localizedDescription];
            return;
        }
        ResultViewController *resultVC = [[ResultViewController alloc] initWithText:text ?: @""];
        [self.navigationController pushViewController:resultVC animated:YES];
    }];
}

- (void)showHint:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    self.previewImageView.image = image;
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end
