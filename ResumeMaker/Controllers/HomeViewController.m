#import <UIKit/UIKit.h>

@interface HomeViewController : UIViewController
@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.navigationItem.title = @"首页";

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"AI 帮你快速生成专业简历";
    titleLabel.font = [UIFont boldSystemFontOfSize:30];
    titleLabel.numberOfLines = 0;

    UILabel *subtitleLabel = [[UILabel alloc] init];
    subtitleLabel.text = @"只需简单填写信息，AI 自动生成高分简历";
    subtitleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    subtitleLabel.textColor = [UIColor secondaryLabelColor];

    UIButton *createButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [createButton setTitle:@"＋ 开始创建简历" forState:UIControlStateNormal];
    createButton.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    createButton.backgroundColor = [UIColor colorWithRed:0.36 green:0.38 blue:0.96 alpha:1.0];
    [createButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    createButton.layer.cornerRadius = 24;
    createButton.contentEdgeInsets = UIEdgeInsetsMake(14, 24, 14, 24);

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[titleLabel, subtitleLabel, createButton]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 18;
    stack.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:20],
        [stack.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-20],
        [stack.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:30]
    ]];
}

@end
