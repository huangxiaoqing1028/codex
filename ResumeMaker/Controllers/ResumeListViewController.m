#import <UIKit/UIKit.h>

@interface ResumeListViewController : UITableViewController
@property (nonatomic, strong) NSArray<NSDictionary *> *resumes;
@end

@implementation ResumeListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"我的简历";
    self.resumes = @[
        @{@"name": @"前端开发工程师", @"score": @"92分", @"date": @"2024-05-20"},
        @{@"name": @"产品经理", @"score": @"88分", @"date": @"2024-05-15"},
        @{@"name": @"运营专员", @"score": @"85分", @"date": @"2024-05-10"}
    ];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"ResumeCell"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.resumes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ResumeCell" forIndexPath:indexPath];
    NSDictionary *resume = self.resumes[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ · %@", resume[@"name"], resume[@"score"]];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"更新时间：%@", resume[@"date"]];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

@end
