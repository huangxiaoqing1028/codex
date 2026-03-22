#import "NGDisplayViewController.h"
#import "NGNicknameGenerator.h"

@interface NGDisplayViewController ()
@property (nonatomic, copy) NSString *nickname;
@end

@implementation NGDisplayViewController

- (instancetype)initWithNickname:(NSString *)nickname {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _nickname = [nickname copy];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"结果";
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    UILabel *hintLabel = [[UILabel alloc] init];
    hintLabel.translatesAutoresizingMaskIntoConstraints = NO;
    hintLabel.text = @"本次生成网名";
    hintLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    hintLabel.textColor = UIColor.secondaryLabelColor;

    UILabel *nicknameLabel = [[UILabel alloc] init];
    nicknameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    nicknameLabel.font = [UIFont monospacedSystemFontOfSize:36 weight:UIFontWeightBold];
    nicknameLabel.textAlignment = NSTextAlignmentCenter;
    nicknameLabel.numberOfLines = 0;
    nicknameLabel.text = self.nickname.length > 0 ? self.nickname : [NGNicknameGenerator shared].latestNickname;

    UIView *adContainer = [[UIView alloc] init];
    adContainer.translatesAutoresizingMaskIntoConstraints = NO;
    adContainer.backgroundColor = [UIColor colorWithRed:0.95 green:0.96 blue:1 alpha:1.0];
    adContainer.layer.cornerRadius = 14;
    adContainer.layer.borderWidth = 1;
    adContainer.layer.borderColor = [UIColor colorWithRed:0.80 green:0.84 blue:1 alpha:1.0].CGColor;

    UILabel *adTitle = [[UILabel alloc] init];
    adTitle.translatesAutoresizingMaskIntoConstraints = NO;
    adTitle.text = @"广告位（可接入 AdMob / 穿山甲）";
    adTitle.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    adTitle.textAlignment = NSTextAlignmentCenter;

    UILabel *adDetail = [[UILabel alloc] init];
    adDetail.translatesAutoresizingMaskIntoConstraints = NO;
    adDetail.text = @"当前为占位视图，审核前替换为正式广告 SDK 组件";
    adDetail.textColor = UIColor.secondaryLabelColor;
    adDetail.numberOfLines = 0;
    adDetail.textAlignment = NSTextAlignmentCenter;
    adDetail.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];

    [adContainer addSubview:adTitle];
    [adContainer addSubview:adDetail];

    [self.view addSubview:hintLabel];
    [self.view addSubview:nicknameLabel];
    [self.view addSubview:adContainer];

    [NSLayoutConstraint activateConstraints:@[
        [hintLabel.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:28],
        [hintLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],

        [nicknameLabel.topAnchor constraintEqualToAnchor:hintLabel.bottomAnchor constant:16],
        [nicknameLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [nicknameLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],

        [adContainer.topAnchor constraintEqualToAnchor:nicknameLabel.bottomAnchor constant:34],
        [adContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [adContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [adContainer.heightAnchor constraintEqualToConstant:140],

        [adTitle.topAnchor constraintEqualToAnchor:adContainer.topAnchor constant:24],
        [adTitle.leadingAnchor constraintEqualToAnchor:adContainer.leadingAnchor constant:12],
        [adTitle.trailingAnchor constraintEqualToAnchor:adContainer.trailingAnchor constant:-12],

        [adDetail.topAnchor constraintEqualToAnchor:adTitle.bottomAnchor constant:10],
        [adDetail.leadingAnchor constraintEqualToAnchor:adContainer.leadingAnchor constant:16],
        [adDetail.trailingAnchor constraintEqualToAnchor:adContainer.trailingAnchor constant:-16],
        [adDetail.bottomAnchor constraintLessThanOrEqualToAnchor:adContainer.bottomAnchor constant:-16]
    ]];
}

@end
