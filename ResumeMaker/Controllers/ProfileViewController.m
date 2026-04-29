#import <UIKit/UIKit.h>
@interface ProfileViewController : UITableViewController
@property NSArray<NSString*> *items;
@end
@implementation ProfileViewController
- (void)viewDidLoad { [super viewDidLoad]; self.title=@"我的"; self.view.backgroundColor=[UIColor colorWithWhite:0.97 alpha:1]; self.items=@[@"我的订单",@"我的收藏",@"浏览记录",@"帮助与反馈",@"设置"]; [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"p"]; self.tableView.separatorStyle=0;
    UIView *h=[[UIView alloc] initWithFrame:CGRectMake(0,0,self.view.bounds.size.width,190)];
    UIView *profile=[[UIView alloc] initWithFrame:CGRectMake(16,12,self.view.bounds.size.width-32,82)]; profile.backgroundColor=UIColor.whiteColor; profile.layer.cornerRadius=16;
    UILabel *n=[[UILabel alloc] initWithFrame:CGRectMake(20,20,120,30)]; n.text=@"张一鸣"; n.font=[UIFont boldSystemFontOfSize:24]; [profile addSubview:n];
    UIView *vip=[[UIView alloc] initWithFrame:CGRectMake(16,106,self.view.bounds.size.width-32,72)]; vip.backgroundColor=[UIColor colorWithRed:0.13 green:0.16 blue:0.25 alpha:1]; vip.layer.cornerRadius=14;
    UILabel *vl=[[UILabel alloc] initWithFrame:CGRectMake(16,18,160,26)]; vl.text=@"高级会员"; vl.textColor=UIColor.whiteColor; vl.font=[UIFont boldSystemFontOfSize:22]; [vip addSubview:vl];
    [h addSubview:profile]; [h addSubview:vip]; self.tableView.tableHeaderView=h;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{return self.items.count;}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{return 64;}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:@"p" forIndexPath:indexPath]; cell.textLabel.text=self.items[indexPath.row]; cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator; return cell;}
@end
