#import "AchievementViewController.h"
#import "ProgressManager.h"
@implementation AchievementViewController
- (void)viewDidLoad { [super viewDidLoad]; self.view.backgroundColor=UIColor.blackColor; self.title=@"成就"; UITextView *tv=[[UITextView alloc]initWithFrame:self.view.bounds]; tv.editable=NO; tv.backgroundColor=UIColor.blackColor; tv.textColor=UIColor.whiteColor; NSArray *ach=[ProgressManager shared].achievements.allObjects; tv.text=[NSString stringWithFormat:@"已解锁成就（%lu）\n%@",(unsigned long)ach.count,[ach componentsJoinedByString:@"\n"]?:@"暂无"]; [self.view addSubview:tv]; }
@end
