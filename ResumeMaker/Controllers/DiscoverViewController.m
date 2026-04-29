#import <UIKit/UIKit.h>
@interface DiscoverViewController : UITableViewController
@property NSArray<NSDictionary*> *articles;
@end
@implementation DiscoverViewController
- (void)viewDidLoad { [super viewDidLoad]; self.title=@"发现"; self.view.backgroundColor=[UIColor colorWithWhite:0.97 alpha:1]; self.tableView.separatorStyle=0;
    self.articles=@[@{@"t":@"如何写出面试官满意的简历?",@"s":@"从 0 到 1 教你打造高通过率简历",@"r":@"1.2w 阅读"},@{@"t":@"2024 最新面试趋势与高频问题",@"s":@"提前准备，轻松拿下 Offer",@"r":@"8563 阅读"}];
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"a"];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{return self.articles.count+1;}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{return indexPath.row==0?120:110;}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath { UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:@"a" forIndexPath:indexPath]; cell.backgroundColor=UIColor.clearColor; for(UIView*v in cell.contentView.subviews){[v removeFromSuperview];}
    if(indexPath.row==0){ NSArray *titles=@[@"求职攻略",@"面试技巧",@"简历案例",@"行业资讯"]; CGFloat w=(tableView.bounds.size.width-40)/4.0; for(int i=0;i<4;i++){UIView *item=[[UIView alloc] initWithFrame:CGRectMake(10+i*w,10,w-8,96)]; item.backgroundColor=UIColor.whiteColor; item.layer.cornerRadius=14; UILabel *l=[[UILabel alloc] initWithFrame:CGRectMake(8,58,w-24,30)]; l.font=[UIFont systemFontOfSize:13 weight:UIFontWeightSemibold]; l.textAlignment=1; l.text=titles[i]; [item addSubview:l]; [cell.contentView addSubview:item];}}
    else {NSDictionary *d=self.articles[indexPath.row-1]; UIView *card=[[UIView alloc] initWithFrame:CGRectMake(12,6,tableView.bounds.size.width-24,96)]; card.backgroundColor=UIColor.whiteColor; card.layer.cornerRadius=14; UILabel *t=[[UILabel alloc] initWithFrame:CGRectMake(16,12,card.bounds.size.width-32,24)]; t.text=d[@"t"]; t.font=[UIFont boldSystemFontOfSize:19]; UILabel *s=[[UILabel alloc] initWithFrame:CGRectMake(16,40,card.bounds.size.width-32,20)]; s.text=d[@"s"]; s.textColor=UIColor.secondaryLabelColor; UILabel *r=[[UILabel alloc] initWithFrame:CGRectMake(16,64,120,20)]; r.text=d[@"r"]; r.textColor=UIColor.tertiaryLabelColor; [card addSubview:t];[card addSubview:s];[card addSubview:r]; [cell.contentView addSubview:card]; }
    return cell; }
@end
