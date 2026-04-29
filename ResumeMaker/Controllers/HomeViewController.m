#import <UIKit/UIKit.h>

@interface RMFeatureItemView : UIView
- (instancetype)initWithIcon:(NSString *)icon title:(NSString *)title subtitle:(NSString *)subtitle;
@end

@implementation RMFeatureItemView
- (instancetype)initWithIcon:(NSString *)icon title:(NSString *)title subtitle:(NSString *)subtitle {
    if (self = [super initWithFrame:CGRectZero]) {
        self.layer.cornerRadius = 16;
        self.backgroundColor = [UIColor whiteColor];
        UIImageView *iconView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:icon]];
        iconView.tintColor = [UIColor colorWithRed:0.36 green:0.38 blue:0.96 alpha:1.0];
        iconView.translatesAutoresizingMaskIntoConstraints = NO;

        UILabel *t = [UILabel new]; t.text = title; t.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
        UILabel *s = [UILabel new]; s.text = subtitle; s.font = [UIFont systemFontOfSize:12]; s.textColor = UIColor.secondaryLabelColor;
        UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[iconView, t, s]];
        stack.axis = UILayoutConstraintAxisVertical; stack.spacing = 8; stack.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:stack];
        [NSLayoutConstraint activateConstraints:@[
            [iconView.heightAnchor constraintEqualToConstant:22],[iconView.widthAnchor constraintEqualToConstant:22],
            [stack.topAnchor constraintEqualToAnchor:self.topAnchor constant:14],[stack.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:12],[stack.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-12]
        ]];
    }
    return self;
}
@end

@interface HomeViewController : UIViewController @end
@implementation HomeViewController
- (void)viewDidLoad { [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1];
    UIScrollView *scroll = [UIScrollView new]; scroll.translatesAutoresizingMaskIntoConstraints = NO; [self.view addSubview:scroll];
    UIView *content = [UIView new]; content.translatesAutoresizingMaskIntoConstraints = NO; [scroll addSubview:content];
    [NSLayoutConstraint activateConstraints:@[[scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],[scroll.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],[scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],[scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],[content.topAnchor constraintEqualToAnchor:scroll.topAnchor],[content.bottomAnchor constraintEqualToAnchor:scroll.bottomAnchor],[content.leadingAnchor constraintEqualToAnchor:scroll.leadingAnchor],[content.trailingAnchor constraintEqualToAnchor:scroll.trailingAnchor],[content.widthAnchor constraintEqualToAnchor:scroll.widthAnchor]]];

    UIView *card = [UIView new]; card.backgroundColor = UIColor.whiteColor; card.layer.cornerRadius = 24; card.translatesAutoresizingMaskIntoConstraints = NO; [content addSubview:card];
    UILabel *hello=[UILabel new]; hello.text=@"你好，张一鸣 👋"; hello.font=[UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    UILabel *title=[UILabel new]; title.text=@"AI 帮你快速生成\n专业简历"; title.numberOfLines=0; title.font=[UIFont boldSystemFontOfSize:40];
    NSMutableAttributedString *att=[[NSMutableAttributedString alloc] initWithString:title.text]; [att addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0.36 green:0.38 blue:0.96 alpha:1] range:NSMakeRange(0,2)]; title.attributedText=att;
    UILabel *sub=[UILabel new]; sub.text=@"只需简单填写信息，AI 自动生成高分简历"; sub.textColor=UIColor.secondaryLabelColor;
    UIView *illustration=[UIView new]; illustration.backgroundColor=[UIColor colorWithRed:0.94 green:0.95 blue:1 alpha:1]; illustration.layer.cornerRadius=22;
    UIButton *cta=[UIButton buttonWithType:UIButtonTypeSystem]; [cta setTitle:@"＋ 开始创建简历" forState:UIControlStateNormal]; cta.backgroundColor=[UIColor colorWithRed:0.36 green:0.38 blue:0.96 alpha:1]; [cta setTitleColor:UIColor.whiteColor forState:UIControlStateNormal]; cta.titleLabel.font=[UIFont boldSystemFontOfSize:20]; cta.layer.cornerRadius=24;
    for(UIView *v in @[hello,title,sub,illustration,cta]) v.translatesAutoresizingMaskIntoConstraints=NO;
    [card addSubview:hello];[card addSubview:title];[card addSubview:sub];[card addSubview:illustration];[card addSubview:cta];

    UIView *f1=[[RMFeatureItemView alloc] initWithIcon:@"wand.and.stars" title:@"智能优化" subtitle:@"提升简历竞争力"];
    UIView *f2=[[RMFeatureItemView alloc] initWithIcon:@"doc.badge.gearshape" title:@"一键生成" subtitle:@"AI 自动排版"];
    UIView *f3=[[RMFeatureItemView alloc] initWithIcon:@"square.and.arrow.up" title:@"多种导出" subtitle:@"PDF/Word"];
    UIView *f4=[[RMFeatureItemView alloc] initWithIcon:@"lock.shield" title:@"隐私安全" subtitle:@"数据加密"];
    UIStackView *grid1=[[UIStackView alloc] initWithArrangedSubviews:@[f1,f2,f3,f4]]; grid1.distribution=UIStackViewDistributionFillEqually; grid1.spacing=10; grid1.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:grid1];

    [NSLayoutConstraint activateConstraints:@[
        [card.topAnchor constraintEqualToAnchor:content.topAnchor constant:14],[card.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:12],[card.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-12],[card.bottomAnchor constraintEqualToAnchor:content.bottomAnchor constant:-20],
        [hello.topAnchor constraintEqualToAnchor:card.topAnchor constant:22],[hello.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:18],
        [title.topAnchor constraintEqualToAnchor:hello.bottomAnchor constant:16],[title.leadingAnchor constraintEqualToAnchor:hello.leadingAnchor],
        [sub.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:10],[sub.leadingAnchor constraintEqualToAnchor:hello.leadingAnchor],
        [illustration.topAnchor constraintEqualToAnchor:sub.bottomAnchor constant:18],[illustration.leadingAnchor constraintEqualToAnchor:hello.leadingAnchor],[illustration.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18],[illustration.heightAnchor constraintEqualToConstant:220],
        [cta.topAnchor constraintEqualToAnchor:illustration.bottomAnchor constant:18],[cta.leadingAnchor constraintEqualToAnchor:hello.leadingAnchor],[cta.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18],[cta.heightAnchor constraintEqualToConstant:52],
        [grid1.topAnchor constraintEqualToAnchor:cta.bottomAnchor constant:16],[grid1.leadingAnchor constraintEqualToAnchor:hello.leadingAnchor],[grid1.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18],[grid1.heightAnchor constraintEqualToConstant:106],[grid1.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-16]
    ]];
}
@end
