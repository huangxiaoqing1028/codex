#import "ResumeEditorViewController.h"
#import "ResumeModel.h"
#import "ResumeStore.h"

@interface ResumeEditorViewController ()
@property UITextField *nameField; @property UITextField *phoneField; @property UITextField *emailField; @property UITextField *roleField; @property UITextView *summaryView;
@end
@implementation ResumeEditorViewController
- (void)viewDidLoad { [super viewDidLoad]; self.title=@"创建简历"; self.view.backgroundColor=UIColor.systemBackgroundColor;
    UIScrollView *s=[UIScrollView new]; s.frame=self.view.bounds; s.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight; [self.view addSubview:s];
    UIStackView *stack=[UIStackView new]; stack.axis=UILayoutConstraintAxisVertical; stack.spacing=12; stack.frame=CGRectMake(16,16,self.view.bounds.size.width-32,520); [s addSubview:stack];
    _nameField=[self field:@"姓名"]; _phoneField=[self field:@"电话"]; _emailField=[self field:@"邮箱"]; _roleField=[self field:@"求职岗位"]; _summaryView=[UITextView new]; _summaryView.layer.borderWidth=1; _summaryView.layer.borderColor=UIColor.systemGray5Color.CGColor; _summaryView.layer.cornerRadius=10; _summaryView.font=[UIFont systemFontOfSize:16]; _summaryView.text=@"个人优势与项目经验";
    [stack addArrangedSubview:_nameField]; [stack addArrangedSubview:_phoneField]; [stack addArrangedSubview:_emailField]; [stack addArrangedSubview:_roleField]; [stack addArrangedSubview:_summaryView]; _summaryView.heightAnchor.active=YES; _summaryView.heightAnchor.constant=140;
    UIButton *save=[UIButton buttonWithType:UIButtonTypeSystem]; [save setTitle:@"保存并导出 PDF" forState:UIControlStateNormal]; save.backgroundColor=[UIColor colorWithRed:0.36 green:0.38 blue:0.96 alpha:1]; [save setTitleColor:UIColor.whiteColor forState:UIControlStateNormal]; save.layer.cornerRadius=12; save.frame=CGRectMake(0,0,100,50); [save addTarget:self action:@selector(saveTap) forControlEvents:UIControlEventTouchUpInside]; [stack addArrangedSubview:save];
}
- (UITextField *)field:(NSString *)p { UITextField *f=[UITextField new]; f.placeholder=p; f.borderStyle=UITextBorderStyleRoundedRect; f.heightAnchor.active=YES; f.heightAnchor.constant=44; return f; }
- (void)saveTap { ResumeModel *m=[ResumeModel new]; m.resumeId=NSUUID.UUID.UUIDString; m.name=_nameField.text; m.phone=_phoneField.text; m.email=_emailField.text; m.targetRole=_roleField.text; m.summary=_summaryView.text; m.updatedAt=[NSDate date]; [[ResumeStore shared] saveResume:m];
    NSString *txt=[NSString stringWithFormat:@"%@\n%@\n%@\n%@\n%@",m.name,m.phone,m.email,m.targetRole,m.summary]; NSString *path=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES).firstObject stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.pdf",m.name.length?m.name:@"resume"]]; UIGraphicsPDFRenderer *r=[[UIGraphicsPDFRenderer alloc] initWithBounds:CGRectMake(0,0,595,842)]; [r writePDFToURL:[NSURL fileURLWithPath:path] withActions:^(UIGraphicsPDFRendererContext * _Nonnull c){ [txt drawInRect:CGRectMake(32,32,531,778) withAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:18]}]; }];
    UIAlertController *a=[UIAlertController alertControllerWithTitle:@"已保存" message:[NSString stringWithFormat:@"本地已生成：%@",path.lastPathComponent] preferredStyle:1]; [a addAction:[UIAlertAction actionWithTitle:@"确定" style:0 handler:nil]]; [self presentViewController:a animated:YES completion:nil];
}
@end
