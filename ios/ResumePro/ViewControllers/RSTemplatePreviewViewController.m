#import "RSTemplatePreviewViewController.h"
#import "RSResume.h"
#import "RSTemplateService.h"
#import "RSTemplate.h"
#import "RSResumeRenderView.h"
#import "RSPaywallViewController.h"
#import "RSSubscriptionService.h"

@interface RSTemplatePreviewViewController () <UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, strong) RSResume *resume;
@property (nonatomic, strong) NSArray<RSTemplate *> *templates;
@property (nonatomic, strong) RSResumeRenderView *renderView;
@property (nonatomic, strong) UICollectionView *collectionView;
@end

@implementation RSTemplatePreviewViewController

- (instancetype)initWithResume:(RSResume *)resume {
    self = [super init];
    if (self) { _resume = resume; }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.title = @"模板切换";
    self.templates = [[RSTemplateService shared] allTemplates];

    self.renderView = [[RSResumeRenderView alloc] initWithFrame:CGRectZero];
    self.renderView.translatesAutoresizingMaskIntoConstraints = NO;
    self.renderView.layer.cornerRadius = 14;
    self.renderView.layer.masksToBounds = YES;

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.itemSize = CGSizeMake(140, 44);
    layout.minimumInteritemSpacing = 8;

    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.backgroundColor = UIColor.clearColor;
    [self.collectionView registerClass:UICollectionViewCell.class forCellWithReuseIdentifier:@"cell"];

    [self.view addSubview:self.renderView];
    [self.view addSubview:self.collectionView];

    [NSLayoutConstraint activateConstraints:@[
        [self.renderView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:16],
        [self.renderView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.renderView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.renderView.heightAnchor constraintEqualToConstant:480],

        [self.collectionView.topAnchor constraintEqualToAnchor:self.renderView.bottomAnchor constant:16],
        [self.collectionView.leadingAnchor constraintEqualToAnchor:self.renderView.leadingAnchor],
        [self.collectionView.trailingAnchor constraintEqualToAnchor:self.renderView.trailingAnchor],
        [self.collectionView.heightAnchor constraintEqualToConstant:52],
    ]];

    RSTemplate *initial = [[RSTemplateService shared] templateById:self.resume.templateId];
    [self.renderView configureWithResume:self.resume template:initial];
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
    label.text = item.premium ? [item.name stringByAppendingString:@" · Pro"] : item.name;
    label.textColor = UIColor.labelColor;
    cell.contentView.layer.cornerRadius = 10;
    cell.contentView.layer.borderWidth = 1;
    cell.contentView.layer.borderColor = UIColor.systemGray4Color.CGColor;

    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    RSTemplate *item = self.templates[indexPath.item];
    BOOL isPro = [RSSubscriptionService shared].isPro;
    if (item.premium && !isPro) {
        [self.navigationController pushViewController:[[RSPaywallViewController alloc] init] animated:YES];
        return;
    }
    self.resume.templateId = item.templateId;
    [self.renderView configureWithResume:self.resume template:item];
}

@end
