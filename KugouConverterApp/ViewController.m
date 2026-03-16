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
@property (nonatomic, strong) UIButton *diagnosticButton;
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
    subtitle.text = @"KGM/KGG/KMG/VPR → OC多策略解密 → FFmpeg多参数回退 → 标准MP3";
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

    self.diagnosticButton = [self primaryButtonWithTitle:@"导出诊断" action:@selector(exportDiagnosticAction)];
    self.diagnosticButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.diagnosticButton.backgroundColor = [UIColor colorWithRed:0.15 green:0.68 blue:0.56 alpha:1];

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
    [self.cardView addSubview:self.diagnosticButton];
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

        [self.diagnosticButton.centerYAnchor constraintEqualToAnchor:self.convertButton.centerYAnchor],
        [self.diagnosticButton.leadingAnchor constraintEqualToAnchor:self.convertButton.trailingAnchor constant:10],

        [self.indicator.centerYAnchor constraintEqualToAnchor:self.convertButton.centerYAnchor],
        [self.indicator.leadingAnchor constraintEqualToAnchor:self.diagnosticButton.trailingAnchor constant:10],

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


- (NSArray<UTType *> *)supportedPickerTypes API_AVAILABLE(ios(14.0)) {
    NSMutableArray<UTType *> *types = [NSMutableArray arrayWithArray:@[UTTypeAudio, UTTypeData, UTTypeContent]];

    NSArray<NSString *> *exts = @[@"kgm", @"kmg", @"kgg", @"vpr", @"mp3", @"wav", @"m4a", @"flac", @"aac"];
    for (NSString *ext in exts) {
        UTType *customType = [UTType typeWithFilenameExtension:ext];
        if (customType) {
            [types addObject:customType];
        }
    }
    return types;
}

- (void)pickFile {
    NSArray<UTType *> *types;
    if (@available(iOS 14.0, *)) {
        types = [self supportedPickerTypes];
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

- (void)exportDiagnosticAction {
    NSURL *documents = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
    if (!documents) {
        self.statusLabel.text = @"导出失败：无法访问 Documents 目录";
        return;
    }

    NSURL *logURL = [documents URLByAppendingPathComponent:@"ffmpeg_last_error.log"];
    NSString *logText = @"(ffmpeg_last_error.log 不存在，可能尚未触发 ffmpeg 失败)";
    NSData *logData = [NSData dataWithContentsOfURL:logURL];
    if (logData.length > 0) {
        logText = [[NSString alloc] initWithData:logData encoding:NSUTF8StringEncoding] ?: @"(日志编码不可读)";
    }

    NSString *candidateInfo = [self.converter latestDecryptCandidateInfo];
    if (candidateInfo.length == 0) {
        candidateInfo = @"(暂无候选信息，请先执行一次转换)";
    }

    NSString *ffmpegSummary = [self.converter latestFFmpegSummary];
    if (ffmpegSummary.length == 0) {
        ffmpegSummary = @"(暂无摘要，请查看完整 ffmpeg_last_error.log)";
    }

    NSString *selected = self.selectedFileURL.lastPathComponent ?: @"(未选择文件)";
    NSString *status = self.statusLabel.text ?: @"";

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSString *time = [formatter stringFromDate:[NSDate date]];

    NSString *report = [NSString stringWithFormat:
                        @"Kugou Converter 诊断导出\n时间: %@\n文件: %@\n状态: %@\n\n=== ffmpeg摘要 ===\n%@\n\n=== 解密候选信息 ===\n%@\n\n=== ffmpeg_last_error.log ===\n%@\n",
                        time,
                        selected,
                        status,
                        ffmpegSummary,
                        candidateInfo,
                        logText];

    NSURL *diagDir = [documents URLByAppendingPathComponent:@"Diagnostics" isDirectory:YES];
    [[NSFileManager defaultManager] createDirectoryAtURL:diagDir withIntermediateDirectories:YES attributes:nil error:nil];

    NSString *safeName = [[selected stringByReplacingOccurrencesOfString:@"/" withString:@"_"] stringByReplacingOccurrencesOfString:@":" withString:@"_"];
    if (safeName.length == 0) {
        safeName = @"unknown";
    }
    NSString *fileName = [NSString stringWithFormat:@"diagnostic-%@-%@.txt", [time stringByReplacingOccurrencesOfString:@" " withString:@"_"], safeName];
    NSURL *reportURL = [diagDir URLByAppendingPathComponent:fileName];

    NSError *writeError = nil;
    BOOL ok = [report writeToURL:reportURL atomically:YES encoding:NSUTF8StringEncoding error:&writeError];
    if (!ok || writeError) {
        self.statusLabel.text = [NSString stringWithFormat:@"导出失败：%@", writeError.localizedDescription ?: @"未知错误"];
        return;
    }

    UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:@[reportURL] applicationActivities:nil];
    if (activity.popoverPresentationController) {
        activity.popoverPresentationController.sourceView = self.diagnosticButton;
        activity.popoverPresentationController.sourceRect = self.diagnosticButton.bounds;
    }
    [self presentViewController:activity animated:YES completion:nil];
    self.statusLabel.text = [NSString stringWithFormat:@"诊断已导出：%@", reportURL.lastPathComponent ?: @""];
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
