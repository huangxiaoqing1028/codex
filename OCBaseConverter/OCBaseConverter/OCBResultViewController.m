#import "OCBResultViewController.h"

@interface OCBResultViewController ()
@property (nonatomic, copy) NSString *inputValue;
@property (nonatomic, copy) NSString *outputValue;
@property (nonatomic, assign) OCBBaseType sourceBase;
@property (nonatomic, assign) OCBBaseType targetBase;
@end

@implementation OCBResultViewController

- (instancetype)initWithInput:(NSString *)input output:(NSString *)output source:(OCBBaseType)source target:(OCBBaseType)target {
    self = [super init];
    if (self) {
        _inputValue = input;
        _outputValue = output;
        _sourceBase = source;
        _targetBase = target;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self buildUI];
}

- (void)buildUI {
    self.view.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.12 alpha:1];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.text = @"Conversion Result";
    titleLabel.textColor = UIColor.whiteColor;
    titleLabel.font = [UIFont systemFontOfSize:30 weight:UIFontWeightBold];

    UILabel *mappingLabel = [[UILabel alloc] init];
    mappingLabel.translatesAutoresizingMaskIntoConstraints = NO;
    mappingLabel.textColor = [UIColor colorWithWhite:1 alpha:0.72];
    mappingLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    mappingLabel.text = [NSString stringWithFormat:@"%@ → %@", [OCBBaseConverter titleForBase:self.sourceBase], [OCBBaseConverter titleForBase:self.targetBase]];

    UIView *glassCard = [[UIView alloc] init];
    glassCard.translatesAutoresizingMaskIntoConstraints = NO;
    glassCard.backgroundColor = [UIColor colorWithWhite:1 alpha:0.09];
    glassCard.layer.cornerRadius = 20;

    UILabel *inputTitle = [[UILabel alloc] init];
    inputTitle.translatesAutoresizingMaskIntoConstraints = NO;
    inputTitle.text = @"Input";
    inputTitle.textColor = [UIColor colorWithWhite:1 alpha:0.65];
    inputTitle.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];

    UILabel *inputValueLabel = [[UILabel alloc] init];
    inputValueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    inputValueLabel.textColor = UIColor.whiteColor;
    inputValueLabel.font = [UIFont monospacedSystemFontOfSize:22 weight:UIFontWeightMedium];
    inputValueLabel.text = self.inputValue;
    inputValueLabel.numberOfLines = 0;

    UILabel *outputTitle = [[UILabel alloc] init];
    outputTitle.translatesAutoresizingMaskIntoConstraints = NO;
    outputTitle.text = @"Output";
    outputTitle.textColor = [UIColor colorWithWhite:1 alpha:0.65];
    outputTitle.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];

    UILabel *outputValueLabel = [[UILabel alloc] init];
    outputValueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    outputValueLabel.textColor = UIColor.whiteColor;
    outputValueLabel.font = [UIFont monospacedSystemFontOfSize:32 weight:UIFontWeightBold];
    outputValueLabel.text = self.outputValue;
    outputValueLabel.numberOfLines = 0;

    UIButton *copyButton = [UIButton buttonWithType:UIButtonTypeSystem];
    copyButton.translatesAutoresizingMaskIntoConstraints = NO;
    [copyButton setTitle:@"Copy Result" forState:UIControlStateNormal];
    copyButton.backgroundColor = UIColor.whiteColor;
    [copyButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    copyButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    copyButton.layer.cornerRadius = 12;
    [copyButton addTarget:self action:@selector(copyTapped) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:titleLabel];
    [self.view addSubview:mappingLabel];
    [self.view addSubview:glassCard];
    [self.view addSubview:copyButton];

    [glassCard addSubview:inputTitle];
    [glassCard addSubview:inputValueLabel];
    [glassCard addSubview:outputTitle];
    [glassCard addSubview:outputValueLabel];

    [NSLayoutConstraint activateConstraints:@[
        [titleLabel.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:24],
        [titleLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [titleLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],

        [mappingLabel.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:8],
        [mappingLabel.leadingAnchor constraintEqualToAnchor:titleLabel.leadingAnchor],
        [mappingLabel.trailingAnchor constraintEqualToAnchor:titleLabel.trailingAnchor],

        [glassCard.topAnchor constraintEqualToAnchor:mappingLabel.bottomAnchor constant:18],
        [glassCard.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [glassCard.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],

        [inputTitle.topAnchor constraintEqualToAnchor:glassCard.topAnchor constant:18],
        [inputTitle.leadingAnchor constraintEqualToAnchor:glassCard.leadingAnchor constant:16],
        [inputTitle.trailingAnchor constraintEqualToAnchor:glassCard.trailingAnchor constant:-16],

        [inputValueLabel.topAnchor constraintEqualToAnchor:inputTitle.bottomAnchor constant:6],
        [inputValueLabel.leadingAnchor constraintEqualToAnchor:inputTitle.leadingAnchor],
        [inputValueLabel.trailingAnchor constraintEqualToAnchor:inputTitle.trailingAnchor],

        [outputTitle.topAnchor constraintEqualToAnchor:inputValueLabel.bottomAnchor constant:16],
        [outputTitle.leadingAnchor constraintEqualToAnchor:inputTitle.leadingAnchor],
        [outputTitle.trailingAnchor constraintEqualToAnchor:inputTitle.trailingAnchor],

        [outputValueLabel.topAnchor constraintEqualToAnchor:outputTitle.bottomAnchor constant:6],
        [outputValueLabel.leadingAnchor constraintEqualToAnchor:inputTitle.leadingAnchor],
        [outputValueLabel.trailingAnchor constraintEqualToAnchor:inputTitle.trailingAnchor],
        [outputValueLabel.bottomAnchor constraintEqualToAnchor:glassCard.bottomAnchor constant:-18],

        [copyButton.topAnchor constraintEqualToAnchor:glassCard.bottomAnchor constant:20],
        [copyButton.leadingAnchor constraintEqualToAnchor:glassCard.leadingAnchor],
        [copyButton.trailingAnchor constraintEqualToAnchor:glassCard.trailingAnchor],
        [copyButton.heightAnchor constraintEqualToConstant:52]
    ]];
}

- (void)copyTapped {
    UIPasteboard.generalPasteboard.string = self.outputValue;

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Copied"
                                                                   message:@"Result has been copied to clipboard."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alert animated:YES completion:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.9 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [alert dismissViewControllerAnimated:YES completion:nil];
    });
}

@end
