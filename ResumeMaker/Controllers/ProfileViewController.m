#import <UIKit/UIKit.h>

@interface ProfileViewController : UITableViewController
@property (nonatomic, strong) NSArray<NSString *> *items;
@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"我的";
    self.items = @[@"我的订单", @"我的收藏", @"浏览记录", @"帮助与反馈", @"设置"];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"ProfileCell"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ProfileCell" forIndexPath:indexPath];
    cell.textLabel.text = self.items[indexPath.row];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

@end
