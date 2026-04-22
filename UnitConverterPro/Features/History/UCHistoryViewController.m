#import "UCHistoryViewController.h"
#import "UCHistoryStore.h"
#import "UCConversionRecord.h"
#import "UCTheme.h"

@interface UCHistoryViewController () <UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray<UCConversionRecord *> *records;
@end

@implementation UCHistoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"历史记录";
    self.view.backgroundColor = [UCTheme backgroundColor];

    UIBarButtonItem *clearButton = [[UIBarButtonItem alloc] initWithTitle:@"清空"
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(clearTapped)];
    self.navigationItem.rightBarButtonItem = clearButton;

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.tableView.dataSource = self;
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.tableView];

    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.records = [[UCHistoryStore shared] allRecords];
    [self.tableView reloadData];
}

- (void)clearTapped {
    [[UCHistoryStore shared] clear];
    self.records = @[];
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.records.count ?: 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    if (self.records.count == 0) {
        cell.textLabel.text = @"暂无记录，去转换一次试试。";
        cell.detailTextLabel.text = nil;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }

    UCConversionRecord *record = self.records[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"[%@] %@", record.categoryName, record.inputText];
    cell.detailTextLabel.text = record.outputText;
    cell.textLabel.numberOfLines = 0;
    cell.detailTextLabel.numberOfLines = 0;
    return cell;
}

@end
