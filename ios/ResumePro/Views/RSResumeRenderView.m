#import "RSResumeRenderView.h"
#import "RSResume.h"
#import "RSTemplate.h"

@interface RSResumeRenderView ()
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *jobLabel;
@property (nonatomic, strong) UITextView *textView;
@end

@implementation RSResumeRenderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [UIFont boldSystemFontOfSize:30];

        _jobLabel = [[UILabel alloc] init];
        _jobLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];

        _textView = [[UITextView alloc] init];
        _textView.editable = NO;
        _textView.backgroundColor = UIColor.clearColor;
        _textView.font = [UIFont systemFontOfSize:14];

        for (UIView *v in @[_nameLabel, _jobLabel, _textView]) {
            v.translatesAutoresizingMaskIntoConstraints = NO;
            [self addSubview:v];
        }

        [NSLayoutConstraint activateConstraints:@[
            [_nameLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:28],
            [_nameLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:24],
            [_nameLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-24],

            [_jobLabel.topAnchor constraintEqualToAnchor:_nameLabel.bottomAnchor constant:8],
            [_jobLabel.leadingAnchor constraintEqualToAnchor:_nameLabel.leadingAnchor],
            [_jobLabel.trailingAnchor constraintEqualToAnchor:_nameLabel.trailingAnchor],

            [_textView.topAnchor constraintEqualToAnchor:_jobLabel.bottomAnchor constant:18],
            [_textView.leadingAnchor constraintEqualToAnchor:_nameLabel.leadingAnchor],
            [_textView.trailingAnchor constraintEqualToAnchor:_nameLabel.trailingAnchor],
            [_textView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-20],
        ]];
    }
    return self;
}

- (void)configureWithResume:(RSResume *)resume template:(RSTemplate *)templateModel {
    self.backgroundColor = templateModel.backgroundColor;
    self.nameLabel.textColor = templateModel.titleColor;
    self.jobLabel.textColor = templateModel.titleColor;
    self.textView.textColor = templateModel.bodyColor;

    self.nameLabel.text = resume.fullName.length ? resume.fullName : @"未命名候选人";
    self.jobLabel.text = resume.jobTitle.length ? resume.jobTitle : @"目标岗位";

    NSDictionary *titleAttrs = @{ NSFontAttributeName:[UIFont systemFontOfSize:13 weight:UIFontWeightBold], NSForegroundColorAttributeName:templateModel.titleColor };
    NSDictionary *bodyAttrs = @{ NSFontAttributeName:[UIFont systemFontOfSize:14], NSForegroundColorAttributeName:templateModel.bodyColor };

    NSMutableAttributedString *content = [[NSMutableAttributedString alloc] init];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:@"联系方式\n" attributes:titleAttrs]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ | %@\n\n", resume.phone.length ? resume.phone : @"电话", resume.email.length ? resume.email : @"邮箱"] attributes:bodyAttrs]];

    [content appendAttributedString:[[NSAttributedString alloc] initWithString:@"个人简介\n" attributes:titleAttrs]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n\n", resume.summary.length ? resume.summary : @"请填写个人简介"] attributes:bodyAttrs]];

    [content appendAttributedString:[[NSAttributedString alloc] initWithString:@"教育经历\n" attributes:titleAttrs]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n\n", resume.education.length ? resume.education : @"请填写教育经历"] attributes:bodyAttrs]];

    [content appendAttributedString:[[NSAttributedString alloc] initWithString:@"工作经历\n" attributes:titleAttrs]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n\n", resume.experience.length ? resume.experience : @"请填写工作经历"] attributes:bodyAttrs]];

    [content appendAttributedString:[[NSAttributedString alloc] initWithString:@"技能证书\n" attributes:titleAttrs]];
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:(resume.skills.length ? resume.skills : @"请填写技能") attributes:bodyAttrs]];

    self.textView.attributedText = content;
}

@end
