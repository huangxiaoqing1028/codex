#import "UCConverterViewController.h"
#import "UCConversionEngine.h"
#import "UCConversionRecord.h"
#import "UCHistoryStore.h"
#import "UCHistoryViewController.h"
#import "UCUnitCategory.h"
#import "UCUnitDefinition.h"
#import "UCCardView.h"
#import "UCTheme.h"

@interface UCConverterViewController () <UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate>
@property (nonatomic, strong) NSArray<UCUnitCategory *> *categories;
@property (nonatomic, strong) UCUnitCategory *selectedCategory;
@property (nonatomic, strong) UCUnitDefinition *fromUnit;
@property (nonatomic, strong) UCUnitDefinition *toUnit;

@property (nonatomic, strong) UISegmentedControl *categoryControl;
@property (nonatomic, strong) UITextField *inputField;
@property (nonatomic, strong) UIPickerView *pickerView;
@property (nonatomic, strong) UILabel *resultLabel;
@end

@implementation UCConverterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"单位换算 Pro";
    self.view.backgroundColor = [UCTheme backgroundColor];

    self.categories = [[UCConversionEngine shared] allCategories];
    self.selectedCategory = self.categories.firstObject;
    self.fromUnit = self.selectedCategory.units.firstObject;
    self.toUnit = self.selectedCategory.units.count > 1 ? self.selectedCategory.units[1] : self.selectedCategory.units.firstObject;

    [self buildUI];
    [self refreshResult];

    UIBarButtonItem *historyButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"clock.arrow.circlepath"]
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(showHistory)];
    self.navigationItem.rightBarButtonItem = historyButton;
}

- (void)buildUI {
    NSMutableArray<NSString *> *titles = [NSMutableArray array];
    for (UCUnitCategory *cat in self.categories) {
        [titles addObject:cat.displayName];
    }

    self.categoryControl = [[UISegmentedControl alloc] initWithItems:titles];
    self.categoryControl.selectedSegmentIndex = 0;
    [self.categoryControl addTarget:self action:@selector(categoryChanged:) forControlEvents:UIControlEventValueChanged];
    self.categoryControl.translatesAutoresizingMaskIntoConstraints = NO;

    UCCardView *inputCard = [[UCCardView alloc] initWithFrame:CGRectZero];
    inputCard.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *inputTitle = [[UILabel alloc] init];
    inputTitle.text = @"输入数值";
    inputTitle.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    inputTitle.textColor = [UCTheme secondaryText];
    inputTitle.translatesAutoresizingMaskIntoConstraints = NO;

    self.inputField = [[UITextField alloc] init];
    self.inputField.placeholder = @"例如 123.45";
    self.inputField.font = [UIFont monospacedDigitSystemFontOfSize:28 weight:UIFontWeightBold];
    self.inputField.keyboardType = UIKeyboardTypeDecimalPad;
    self.inputField.delegate = self;
    [self.inputField addTarget:self action:@selector(refreshResult) forControlEvents:UIControlEventEditingChanged];
    self.inputField.translatesAutoresizingMaskIntoConstraints = NO;

    [inputCard addSubview:inputTitle];
    [inputCard addSubview:self.inputField];

    UCCardView *resultCard = [[UCCardView alloc] initWithFrame:CGRectZero];
    resultCard.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *resultTitle = [[UILabel alloc] init];
    resultTitle.text = @"换算结果";
    resultTitle.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    resultTitle.textColor = [UCTheme secondaryText];
    resultTitle.translatesAutoresizingMaskIntoConstraints = NO;

    self.resultLabel = [[UILabel alloc] init];
    self.resultLabel.font = [UIFont monospacedDigitSystemFontOfSize:32 weight:UIFontWeightHeavy];
    self.resultLabel.adjustsFontSizeToFitWidth = YES;
    self.resultLabel.minimumScaleFactor = 0.4;
    self.resultLabel.translatesAutoresizingMaskIntoConstraints = NO;

    [resultCard addSubview:resultTitle];
    [resultCard addSubview:self.resultLabel];

    self.pickerView = [[UIPickerView alloc] init];
    self.pickerView.dataSource = self;
    self.pickerView.delegate = self;
    self.pickerView.translatesAutoresizingMaskIntoConstraints = NO;

    UIButton *swapButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [swapButton setTitle:@"交换单位" forState:UIControlStateNormal];
    swapButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    swapButton.backgroundColor = [UCTheme primaryTint];
    [swapButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    swapButton.layer.cornerRadius = 14;
    [swapButton addTarget:self action:@selector(swapUnits) forControlEvents:UIControlEventTouchUpInside];
    swapButton.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:self.categoryControl];
    [self.view addSubview:inputCard];
    [self.view addSubview:self.pickerView];
    [self.view addSubview:resultCard];
    [self.view addSubview:swapButton];

    UILayoutGuide *g = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.categoryControl.topAnchor constraintEqualToAnchor:g.topAnchor constant:14],
        [self.categoryControl.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:16],
        [self.categoryControl.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-16],

        [inputCard.topAnchor constraintEqualToAnchor:self.categoryControl.bottomAnchor constant:14],
        [inputCard.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:16],
        [inputCard.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-16],

        [inputTitle.topAnchor constraintEqualToAnchor:inputCard.topAnchor constant:16],
        [inputTitle.leadingAnchor constraintEqualToAnchor:inputCard.leadingAnchor constant:16],
        [self.inputField.topAnchor constraintEqualToAnchor:inputTitle.bottomAnchor constant:8],
        [self.inputField.leadingAnchor constraintEqualToAnchor:inputCard.leadingAnchor constant:16],
        [self.inputField.trailingAnchor constraintEqualToAnchor:inputCard.trailingAnchor constant:-16],
        [self.inputField.bottomAnchor constraintEqualToAnchor:inputCard.bottomAnchor constant:-16],

        [self.pickerView.topAnchor constraintEqualToAnchor:inputCard.bottomAnchor constant:8],
        [self.pickerView.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:16],
        [self.pickerView.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-16],
        [self.pickerView.heightAnchor constraintEqualToConstant:180],

        [resultCard.topAnchor constraintEqualToAnchor:self.pickerView.bottomAnchor constant:8],
        [resultCard.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:16],
        [resultCard.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-16],

        [resultTitle.topAnchor constraintEqualToAnchor:resultCard.topAnchor constant:16],
        [resultTitle.leadingAnchor constraintEqualToAnchor:resultCard.leadingAnchor constant:16],
        [self.resultLabel.topAnchor constraintEqualToAnchor:resultTitle.bottomAnchor constant:8],
        [self.resultLabel.leadingAnchor constraintEqualToAnchor:resultCard.leadingAnchor constant:16],
        [self.resultLabel.trailingAnchor constraintEqualToAnchor:resultCard.trailingAnchor constant:-16],
        [self.resultLabel.bottomAnchor constraintEqualToAnchor:resultCard.bottomAnchor constant:-16],

        [swapButton.topAnchor constraintEqualToAnchor:resultCard.bottomAnchor constant:12],
        [swapButton.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:16],
        [swapButton.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-16],
        [swapButton.heightAnchor constraintEqualToConstant:52]
    ]];
}

- (void)categoryChanged:(UISegmentedControl *)control {
    self.selectedCategory = self.categories[control.selectedSegmentIndex];
    self.fromUnit = self.selectedCategory.units.firstObject;
    self.toUnit = self.selectedCategory.units.count > 1 ? self.selectedCategory.units[1] : self.selectedCategory.units.firstObject;
    [self.pickerView reloadAllComponents];
    [self refreshResult];
}

- (void)swapUnits {
    UCUnitDefinition *tmp = self.fromUnit;
    self.fromUnit = self.toUnit;
    self.toUnit = tmp;
    NSUInteger fromIndex = [self.selectedCategory.units indexOfObject:self.fromUnit];
    NSUInteger toIndex = [self.selectedCategory.units indexOfObject:self.toUnit];
    [self.pickerView selectRow:fromIndex inComponent:0 animated:YES];
    [self.pickerView selectRow:toIndex inComponent:1 animated:YES];
    [self refreshResult];
}

- (void)showHistory {
    UCHistoryViewController *vc = [[UCHistoryViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)refreshResult {
    NSString *raw = self.inputField.text.length > 0 ? self.inputField.text : @"0";
    double inputValue = raw.doubleValue;
    double outputValue = [[UCConversionEngine shared] convertValue:inputValue fromUnit:self.fromUnit toUnit:self.toUnit];

    self.resultLabel.text = [NSString stringWithFormat:@"%.6g %@", outputValue, self.toUnit.symbol];

    NSString *inputText = [NSString stringWithFormat:@"%.6g %@", inputValue, self.fromUnit.symbol];
    NSString *outputText = [NSString stringWithFormat:@"%.6g %@", outputValue, self.toUnit.symbol];
    UCConversionRecord *record = [[UCConversionRecord alloc] initWithCategoryName:self.selectedCategory.displayName
                                                                         inputText:inputText
                                                                        outputText:outputText
                                                                         timestamp:[NSDate date]];
    [[UCHistoryStore shared] addRecord:record];
}

#pragma mark - UIPickerView

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 2;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.selectedCategory.units.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    UCUnitDefinition *unit = self.selectedCategory.units[row];
    return [NSString stringWithFormat:@"%@ (%@)", unit.displayName, unit.symbol];
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return 38;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    UCUnitDefinition *unit = self.selectedCategory.units[row];
    if (component == 0) {
        self.fromUnit = unit;
    } else {
        self.toUnit = unit;
    }
    [self refreshResult];
}

@end
