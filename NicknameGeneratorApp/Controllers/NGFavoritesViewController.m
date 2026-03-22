#import "NGFavoritesViewController.h"
#import "NGNicknameGenerator.h"

@interface NGFavoritesViewController () <UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSString *> *favorites;
@end

@implementation NGFavoritesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"收藏";
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
    self.favorites = [NGNicknameGenerator shared].favoriteNicknames;
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return MAX(self.favorites.count, 1);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"favorite_cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"favorite_cell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    if (self.favorites.count == 0) {
        cell.textLabel.text = @"还没有收藏，去生成页试试吧";
        cell.detailTextLabel.text = @"点击“收藏”即可同步到这里";
        cell.textLabel.textColor = UIColor.secondaryLabelColor;
    } else {
        cell.textLabel.text = self.favorites[indexPath.row];
        cell.detailTextLabel.text = @"已收藏";
        cell.textLabel.textColor = UIColor.labelColor;
    }

    return cell;
}

@end
