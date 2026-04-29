#import <UIKit/UIKit.h>

@interface DiscoverViewController : UITableViewController
@property (nonatomic, strong) NSArray<NSString *> *articles;
@end

@implementation DiscoverViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"发现";
    self.articles = @[@"如何写出面试官满意的简历", @"2024 最新面试趋势与高频问题", @"不同岗位简历撰写要点"];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"ArticleCell"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.articles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ArticleCell" forIndexPath:indexPath];
    cell.textLabel.text = self.articles[indexPath.row];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

@end
