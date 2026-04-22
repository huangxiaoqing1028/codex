#import "RSTemplatePreviewViewController.h"
#import "RSResume.h"
#import "RSTemplateService.h"
#import "RSTemplate.h"
#import "RSResumeRenderView.h"
#import "RSPaywallViewController.h"
#import "RSSubscriptionService.h"
#import "RSTheme.h"

@interface RSTemplatePreviewViewController () <UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, strong) RSResume *resume;
@property (nonatomic, strong) NSArray<RSTemplate *> *templates;
@property (nonatomic, strong) RSResumeRenderView *renderView;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIButton *applyButton;
@property (nonatomic, strong) RSTemplate *selectedTemplate;
@end

@implementation RSTemplatePreviewViewController

- (instancetype)initWithResume:(RSResume *)resume {
    self = [super init];
    if (self) { _resume = resume; }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [RSTheme bgPrimary];
    self.title = @"模板中心";
    self.templates = [[RSTemplateService shared] allTemplates];
    self.selectedTemplate = [[RSTemplateService shared] templateById:self.resume.templateId];

    self.renderView = [[RSResumeRenderView alloc] initWithFrame:CGRectZero];
    self.renderView.translatesAutoresizingMaskIntoConstraints = NO;
    self.renderView.layer.cornerRadius = 18;
    self.renderView.layer.masksToBounds = YES;
    self.renderView.layer.borderColor = [RSTheme border].CGColor;
    self.renderView.layer.borderWidth = 1;

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.itemSize = CGSizeMake(170, 56);
    layout.minimumLineSpacing = 10;

    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.backgroundColor = UIColor.clearColor;
    [self.collectionView registerClass:UICollectionViewCell.class forCellWithReuseIdentifier:@"cell"];

    self.applyButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.applyButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.applyButton.backgroundColor = [RSTheme accentGold];
    [self.applyButton setTitleColor:[RSTheme bgPrimary] forState:UIControlStateNormal];
    self.applyButton.layer.cornerRadius = 14;
    self.applyButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    [self.applyButton setTitle:@"应用当前模板" forState:UIControlStateNormal];
    [self.applyButton addTarget:self action:@selector(onApply) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:self.renderView];
    [self.view addSubview:self.collectionView];
    [self.view addSubview:self.applyButton];

    [NSLayoutConstraint activateConstraints:@[
        [self.renderView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:16],
        [self.renderView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.renderView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.renderView.heightAnchor constraintEqualToConstant:500],

        [self.collectionView.topAnchor constraintEqualToAnchor:self.renderView.bottomAnchor constant:14],
        [self.collectionView.leadingAnchor constraintEqualToAnchor:self.renderView.leadingAnchor],
        [self.collectionView.trailingAnchor constraintEqualToAnchor:self.renderView.trailingAnchor],
        [self.collectionView.heightAnchor constraintEqualToConstant:62],

        [self.applyButton.topAnchor constraintEqualToAnchor:self.collectionView.bottomAnchor constant:14],
        [self.applyButton.leadingAnchor constraintEqualToAnchor:self.renderView.leadingAnchor],
        [self.applyButton.trailingAnchor constraintEqualToAnchor:self.renderView.trailingAnchor],
        [self.applyButton.heightAnchor constraintEqualToConstant:52],
    ]];

    [self.renderView configureWithResume:self.resume template:self.selectedTemplate];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.templates.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    RSTemplate *item = self.templates[indexPath.item];

    UILabel *label = [cell.contentView viewWithTag:1001];
    if (!label) {
        label = [[UILabel alloc] initWithFrame:cell.contentView.bounds];
        label.tag = 1001;
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
        [cell.contentView addSubview:label];
    }

    BOOL isSelected = [item.templateId isEqualToString:self.selectedTemplate.templateId];
    label.text = item.premium ? [NSString stringWithFormat:@"%@ · PRO", item.name] : item.name;
    label.textColor = isSelected ? [RSTheme bgPrimary] : [RSTheme textPrimary];
    cell.contentView.backgroundColor = isSelected ? [RSTheme accentGold] : [RSTheme cardBackground];
    cell.contentView.layer.cornerRadius = 12;
    cell.contentView.layer.borderWidth = 1;
    cell.contentView.layer.borderColor = isSelected ? [RSTheme accentGold].CGColor : [RSTheme border].CGColor;

    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    RSTemplate *item = self.templates[indexPath.item];
    if (item.premium && ![RSSubscriptionService shared].isPro) {
        [self.navigationController pushViewController:[[RSPaywallViewController alloc] init] animated:YES];
        return;
    }
    self.selectedTemplate = item;
    [self.renderView configureWithResume:self.resume template:item];
    [self.collectionView reloadData];
}

- (void)onApply {
    self.resume.templateId = self.selectedTemplate.templateId;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"已应用" message:@"模板已应用到当前简历" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
