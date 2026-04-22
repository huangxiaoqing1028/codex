#import "RSMyResumesViewController.h"
#import "RSResumeStore.h"
#import "RSResume.h"
#import "RSTheme.h"

@interface RSMyResumesViewController ()
@property (nonatomic, strong) NSArray<RSResume *> *items;
@property (nonatomic, strong) UILabel *emptyLabel;
@end

@implementation RSMyResumesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"简历资产库";
    self.tableView.backgroundColor = [RSTheme bgPrimary];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    self.emptyLabel = [[UILabel alloc] initWithFrame:self.tableView.bounds];
    self.emptyLabel.text = @"暂无简历，请先去“制作”页面创建";
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.textColor = [RSTheme textSecondary];
    self.emptyLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.items = [[RSResumeStore shared] allResumes];
    self.tableView.backgroundView = self.items.count == 0 ? self.emptyLabel : nil;
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
    cell.backgroundColor = [RSTheme cardBackground];
    cell.textLabel.text = item.fullName.length ? item.fullName : @"未命名简历";
    cell.textLabel.textColor = [RSTheme textPrimary];

    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"yyyy-MM-dd HH:mm";
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ · 模板:%@", [fmt stringFromDate:item.updatedAt], item.templateId];
    cell.detailTextLabel.textColor = [RSTheme textSecondary];
    cell.layer.cornerRadius = 12;
    cell.layer.masksToBounds = YES;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 72;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section { return 10; }

@end
