#import "NGHistoryViewController.h"
#import "NGNicknameGenerator.h"

@interface NGHistoryViewController () <UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSString *> *history;
@end

@implementation NGHistoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"历史";
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];

    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:NGNicknameDataDidChangeNotification object:nil];
    [self reloadData];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reloadData {
    self.history = [NGNicknameGenerator shared].recentNicknames;
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return MAX(self.history.count, 1);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"history_cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"history_cell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    if (self.history.count == 0) {
        cell.textLabel.text = @"还没有历史记录";
        cell.detailTextLabel.text = @"生成新昵称后会显示在这里";
        cell.textLabel.textColor = UIColor.secondaryLabelColor;
    } else {
        cell.textLabel.text = self.history[indexPath.row];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"历史 #%ld", (long)(indexPath.row + 1)];
        cell.textLabel.textColor = UIColor.labelColor;
    }

    return cell;
}

@end
