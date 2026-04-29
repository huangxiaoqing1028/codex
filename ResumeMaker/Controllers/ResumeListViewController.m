#import <UIKit/UIKit.h>

@interface ResumeListViewController : UITableViewController
@property NSArray<NSDictionary *> *resumes;
@end

@implementation ResumeListViewController
- (void)viewDidLoad { [super viewDidLoad];
    self.title=@"我的简历"; self.view.backgroundColor=[UIColor colorWithWhite:0.97 alpha:1];
    self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:nil action:nil];
    self.resumes=@[@{@"name":@"前端开发工程师",@"score":@"92",@"time":@"2024-05-20"},@{@"name":@"产品经理",@"score":@"88",@"time":@"2024-05-15"},@{@"name":@"运营专员",@"score":@"85",@"time":@"2024-05-10"}];
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"c"]; self.tableView.separatorStyle=UITableViewCellSeparatorStyleNone;
    UIView *header=[[UIView alloc] initWithFrame:CGRectMake(0,0,self.view.bounds.size.width,96)];
    UIView *vip=[[UIView alloc] initWithFrame:CGRectMake(16,12,self.view.bounds.size.width-32,76)]; vip.backgroundColor=[UIColor colorWithRed:0.93 green:0.94 blue:1 alpha:1]; vip.layer.cornerRadius=14;
    UILabel *l=[[UILabel alloc] initWithFrame:CGRectMake(16,14,220,24)]; l.text=@"开通会员，解锁全部功能"; l.textColor=[UIColor colorWithRed:0.36 green:0.38 blue:0.96 alpha:1];
    [vip addSubview:l]; [header addSubview:vip]; self.tableView.tableHeaderView=header;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{return self.resumes.count;}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{return 126;}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:@"c" forIndexPath:indexPath]; cell.backgroundColor=UIColor.clearColor;
    for(UIView *v in cell.contentView.subviews){[v removeFromSuperview];}
    UIView *card=[[UIView alloc] initWithFrame:CGRectMake(16,6,tableView.bounds.size.width-32,112)]; card.backgroundColor=UIColor.whiteColor; card.layer.cornerRadius=14;
    NSDictionary *r=self.resumes[indexPath.row];
    UILabel *name=[[UILabel alloc] initWithFrame:CGRectMake(16,16,190,22)]; name.text=r[@"name"]; name.font=[UIFont boldSystemFontOfSize:19];
    UILabel *time=[[UILabel alloc] initWithFrame:CGRectMake(16,42,200,18)]; time.text=[NSString stringWithFormat:@"更新时间：%@",r[@"time"]]; time.font=[UIFont systemFontOfSize:13]; time.textColor=UIColor.secondaryLabelColor;
    UILabel *score=[[UILabel alloc] initWithFrame:CGRectMake(card.bounds.size.width-70,16,50,30)]; score.text=[NSString stringWithFormat:@"%@分",r[@"score"]]; score.textColor=[UIColor colorWithRed:0.36 green:0.38 blue:0.96 alpha:1]; score.font=[UIFont boldSystemFontOfSize:30];
    [card addSubview:name];[card addSubview:time];[card addSubview:score]; [cell.contentView addSubview:card];
    return cell;
}
@end
