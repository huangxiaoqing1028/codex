#import "RSMyResumesViewController.h"
#import "RSResumeStore.h"
#import "RSResume.h"

@interface RSMyResumesViewController ()
@property (nonatomic, strong) NSArray<RSResume *> *items;
@end

@implementation RSMyResumesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"我的简历";
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.items = [[RSResumeStore shared] allResumes];
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    RSResume *item = self.items[indexPath.row];
    cell.textLabel.text = item.fullName.length ? item.fullName : @"未命名简历";
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"yyyy-MM-dd HH:mm";
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ · 模板:%@", [fmt stringFromDate:item.updatedAt], item.templateId];
    return cell;
}

@end
