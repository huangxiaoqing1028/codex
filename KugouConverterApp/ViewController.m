#import "ViewController.h"
#import "KGMAudioConverter.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@interface ViewController () <UIDocumentPickerDelegate>
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UILabel *fileLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UISegmentedControl *formatControl;
@property (nonatomic, strong) UIButton *convertButton;
@property (nonatomic, strong) UIActivityIndicatorView *indicator;
@property (nonatomic, strong) NSURL *selectedFileURL;
@property (nonatomic, strong) KGMAudioConverter *converter;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.converter = [[KGMAudioConverter alloc] init];
    [self setupUI];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.gradientLayer.frame = self.view.bounds;
}

- (void)setupUI {
    self.view.backgroundColor = UIColor.blackColor;

    self.gradientLayer = [CAGradientLayer layer];
    self.gradientLayer.colors = @[(id)[UIColor colorWithRed:0.11 green:0.13 blue:0.28 alpha:1].CGColor,
                                  (id)[UIColor colorWithRed:0.23 green:0.15 blue:0.41 alpha:1].CGColor,
                                  (id)[UIColor colorWithRed:0.07 green:0.24 blue:0.37 alpha:1].CGColor];
    self.gradientLayer.startPoint = CGPointMake(0, 0);
    self.gradientLayer.endPoint = CGPointMake(1, 1);
    [self.view.layer addSublayer:self.gradientLayer];

    UILabel *title = [[UILabel alloc] init];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = @"Kugou Audio Converter";
    title.textColor = UIColor.whiteColor;
    title.font = [UIFont systemFontOfSize:34 weight:UIFontWeightBold];

    UILabel *subtitle = [[UILabel alloc] init];
    subtitle.translatesAutoresizingMaskIntoConstraints = NO;
    subtitle.text = @"KGM → OC解密 → 临时MP3 → FFmpeg → 标准MP3";
    subtitle.textColor = [UIColor colorWithWhite:1 alpha:0.85];
    subtitle.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];

    self.cardView = [[UIView alloc] init];
    self.cardView.translatesAutoresizingMaskIntoConstraints = NO;
    self.cardView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.12];
    self.cardView.layer.cornerRadius = 22;
    self.cardView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.2].CGColor;
    self.cardView.layer.borderWidth = 1;

    UIVisualEffectView *blur = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark]];
    blur.translatesAutoresizingMaskIntoConstraints = NO;
    blur.layer.cornerRadius = 22;
    blur.clipsToBounds = YES;
    [self.cardView addSubview:blur];

    UIButton *pickButton = [self primaryButtonWithTitle:@"选择音频文件" action:@selector(pickFile)];
    pickButton.translatesAutoresizingMaskIntoConstraints = NO;

    self.fileLabel = [[UILabel alloc] init];
    self.fileLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.fileLabel.text = @"尚未选择文件";
    self.fileLabel.textColor = UIColor.whiteColor;
    self.fileLabel.numberOfLines = 2;

    self.formatControl = [[UISegmentedControl alloc] initWithItems:@[@"标准MP3"]];
    self.formatControl.translatesAutoresizingMaskIntoConstraints = NO;
    self.formatControl.selectedSegmentIndex = 0;
    self.formatControl.selectedSegmentTintColor = [UIColor colorWithRed:0.39 green:0.45 blue:1 alpha:1];

    self.convertButton = [self primaryButtonWithTitle:@"开始转换" action:@selector(convertAction)];
    self.convertButton.translatesAutoresizingMaskIntoConstraints = NO;

    self.indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.indicator.translatesAutoresizingMaskIntoConstraints = NO;
    self.indicator.color = UIColor.whiteColor;
    self.indicator.hidesWhenStopped = YES;

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusLabel.text = @"请选择文件后开始转换";
    self.statusLabel.textColor = [UIColor colorWithWhite:1 alpha:0.9];
    self.statusLabel.numberOfLines = 0;
    self.statusLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];

    [self.view addSubview:title];
    [self.view addSubview:subtitle];
    [self.view addSubview:self.cardView];
    [self.cardView addSubview:pickButton];
    [self.cardView addSubview:self.fileLabel];
    [self.cardView addSubview:self.formatControl];
    [self.cardView addSubview:self.convertButton];
    [self.cardView addSubview:self.indicator];
    [self.cardView addSubview:self.statusLabel];

    [NSLayoutConstraint activateConstraints:@[
        [title.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:24],
        [title.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24],

        [subtitle.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:6],
        [subtitle.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],

        [self.cardView.topAnchor constraintEqualToAnchor:subtitle.bottomAnchor constant:24],
        [self.cardView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.cardView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],

        [blur.topAnchor constraintEqualToAnchor:self.cardView.topAnchor],
        [blur.bottomAnchor constraintEqualToAnchor:self.cardView.bottomAnchor],
        [blur.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor],
        [blur.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor],

        [pickButton.topAnchor constraintEqualToAnchor:self.cardView.topAnchor constant:18],
        [pickButton.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:16],

        [self.fileLabel.centerYAnchor constraintEqualToAnchor:pickButton.centerYAnchor],
        [self.fileLabel.leadingAnchor constraintEqualToAnchor:pickButton.trailingAnchor constant:12],
        [self.fileLabel.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-16],

        [self.formatControl.topAnchor constraintEqualToAnchor:pickButton.bottomAnchor constant:20],
        [self.formatControl.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:16],
        [self.formatControl.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-16],

        [self.convertButton.topAnchor constraintEqualToAnchor:self.formatControl.bottomAnchor constant:20],
        [self.convertButton.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:16],

        [self.indicator.centerYAnchor constraintEqualToAnchor:self.convertButton.centerYAnchor],
        [self.indicator.leadingAnchor constraintEqualToAnchor:self.convertButton.trailingAnchor constant:12],

        [self.statusLabel.topAnchor constraintEqualToAnchor:self.convertButton.bottomAnchor constant:18],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:16],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-16],
        [self.statusLabel.bottomAnchor constraintEqualToAnchor:self.cardView.bottomAnchor constant:-18],

        [self.cardView.bottomAnchor constraintLessThanOrEqualToAnchor:self.view.bottomAnchor constant:-20]
    ]];
}

- (UIButton *)primaryButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.backgroundColor = [UIColor colorWithRed:0.39 green:0.45 blue:1 alpha:1];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    button.layer.cornerRadius = 12;
    button.contentEdgeInsets = UIEdgeInsetsMake(10, 16, 10, 16);
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)pickFile {
    NSArray<UTType *> *types;
    if (@available(iOS 15.0, *)) {
        types = @[UTTypeAudio, UTTypeData];
    } else {
        types = @[];
    }
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:types];
    picker.delegate = self;
    picker.allowsMultipleSelection = NO;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *url = urls.firstObject;
    if (!url) { return; }
    self.selectedFileURL = url;
    self.fileLabel.text = url.lastPathComponent;
    self.statusLabel.text = @"文件已选择，点击开始转换。";
}

- (KGOutputFormat)currentFormat {
    return KGOutputFormatMP3;
}

- (void)convertAction {
    if (!self.selectedFileURL) {
        self.statusLabel.text = @"请先选择输入文件。";
        return;
    }

    NSURL *sourceURL = self.selectedFileURL;
    BOOL didStartSecurityScope = NO;
    if ([sourceURL respondsToSelector:@selector(startAccessingSecurityScopedResource)]) {
        didStartSecurityScope = [sourceURL startAccessingSecurityScopedResource];
    }

    NSURL *documents = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
    NSURL *outputDir = [documents URLByAppendingPathComponent:@"ConvertedAudio" isDirectory:YES];

    self.convertButton.enabled = NO;
    [self.indicator startAnimating];
    self.statusLabel.text = @"转换中，请稍候...";

    [self.converter convertFileAtURL:sourceURL outputDir:outputDir format:[self currentFormat] completion:^(NSURL * _Nullable outputURL, NSError * _Nullable error) {
        if (didStartSecurityScope) {
            [sourceURL stopAccessingSecurityScopedResource];
        }

        self.convertButton.enabled = YES;
        [self.indicator stopAnimating];

        if (error) {
            self.statusLabel.text = [NSString stringWithFormat:@"转换失败：%@", error.localizedDescription ?: @"未知错误"];
            return;
        }

        self.statusLabel.text = [NSString stringWithFormat:@"转换成功：\n%@", outputURL.path ?: @""];
    }];
}

@end
