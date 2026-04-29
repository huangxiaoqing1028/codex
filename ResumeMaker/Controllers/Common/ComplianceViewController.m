#import "ComplianceViewController.h"
@implementation ComplianceViewController
- (void)viewDidLoad { [super viewDidLoad]; self.title=@"隐私与合规"; self.view.backgroundColor=UIColor.systemBackgroundColor;
UITextView *t=[[UITextView alloc] initWithFrame:self.view.bounds]; t.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight; t.editable=NO; t.text=@"1. 隐私政策\n2. 用户协议\n3. 个人信息删除申请\n4. 第三方 SDK 列表\n5. 内容审核与投诉机制\n\n上架前请替换为法务审核版本。"; [self.view addSubview:t]; }
@end
