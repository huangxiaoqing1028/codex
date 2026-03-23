#import "NGSettingsViewController.h"
#import "NGNicknameGenerator.h"

@interface NGSettingsViewController ()
@property (nonatomic, strong) UILabel *libraryLabel;
@property (nonatomic, strong) UISwitch *defaultNumberSwitch;
@end

@implementation NGSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"设置";
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];

    UIView *card = [[UIView alloc] init];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    card.backgroundColor = UIColor.whiteColor;
    card.layer.cornerRadius = 14;
    [self.view addSubview:card];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.text = @"生成参数";
    titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];

    self.libraryLabel = [[UILabel alloc] init];
    self.libraryLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.libraryLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    self.libraryLabel.textColor = UIColor.secondaryLabelColor;

    UILabel *numberTitle = [[UILabel alloc] init];
    numberTitle.translatesAutoresizingMaskIntoConstraints = NO;
    numberTitle.text = @"默认附加数字后缀";
    numberTitle.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];

    self.defaultNumberSwitch = [[UISwitch alloc] init];
    self.defaultNumberSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    [self.defaultNumberSwitch addTarget:self action:@selector(toggleDefaultNumber:) forControlEvents:UIControlEventValueChanged];

    UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeSystem];
    clearButton.translatesAutoresizingMaskIntoConstraints = NO;
    [clearButton setTitle:@"清空历史与收藏" forState:UIControlStateNormal];
    clearButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [clearButton addTarget:self action:@selector(clearDataTapped) forControlEvents:UIControlEventTouchUpInside];

    [card addSubview:titleLabel];
    [card addSubview:self.libraryLabel];
    [card addSubview:numberTitle];
    [card addSubview:self.defaultNumberSwitch];
    [card addSubview:clearButton];

    [NSLayoutConstraint activateConstraints:@[
        [card.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:16],
        [card.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [card.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],

        [titleLabel.topAnchor constraintEqualToAnchor:card.topAnchor constant:18],
        [titleLabel.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],

        [self.libraryLabel.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:8],
        [self.libraryLabel.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],

        [numberTitle.topAnchor constraintEqualToAnchor:self.libraryLabel.bottomAnchor constant:20],
        [numberTitle.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [numberTitle.centerYAnchor constraintEqualToAnchor:self.defaultNumberSwitch.centerYAnchor],

        [self.defaultNumberSwitch.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],

        [clearButton.topAnchor constraintEqualToAnchor:numberTitle.bottomAnchor constant:20],
        [clearButton.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [clearButton.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-18]
    ]];

    [self reloadValues];
}

- (void)reloadValues {
    NGNicknameGenerator *generator = [NGNicknameGenerator shared];
    self.libraryLabel.text = [NSString stringWithFormat:@"词库规模：%lu", (unsigned long)generator.libraryCount];
    self.defaultNumberSwitch.on = generator.defaultIncludeNumber;
}

- (void)toggleDefaultNumber:(UISwitch *)sender {
    [NGNicknameGenerator shared].defaultIncludeNumber = sender.isOn;
}

- (void)clearDataTapped {
    [[NGNicknameGenerator shared] clearAllData];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"已清空" message:@"历史和收藏已删除" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
