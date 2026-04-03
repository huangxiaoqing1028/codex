#import "OCBViewController.h"
#import "OCBBaseConverter.h"
#import "OCBResultViewController.h"

@interface OCBViewController () <UITextFieldDelegate>
@property (nonatomic, strong) UITextField *inputField;
@property (nonatomic, strong) UILabel *hintLabel;
@property (nonatomic, strong) UILabel *errorLabel;
@property (nonatomic, strong) UISegmentedControl *fromControl;
@property (nonatomic, strong) UISegmentedControl *toControl;
@end

@implementation OCBViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self buildUI];
}

- (void)buildUI {
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.colors = @[(__bridge id)[UIColor colorWithRed:0.07 green:0.08 blue:0.16 alpha:1].CGColor,
                        (__bridge id)[UIColor colorWithRed:0.14 green:0.05 blue:0.24 alpha:1].CGColor];
    gradient.frame = self.view.bounds;
    [self.view.layer addSublayer:gradient];

    UILabel *title = [[UILabel alloc] init];
    title.text = @"BaseCraft Converter";
    title.textColor = UIColor.whiteColor;
    title.font = [UIFont systemFontOfSize:32 weight:UIFontWeightBold];

    UILabel *subtitle = [[UILabel alloc] init];
    subtitle.text = @"Premium Objective-C converter";
    subtitle.textColor = [UIColor colorWithWhite:1 alpha:0.7];
    subtitle.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];

    self.fromControl = [[UISegmentedControl alloc] initWithItems:@[@"Bin", @"Oct", @"Dec", @"Hex"]];
    self.toControl = [[UISegmentedControl alloc] initWithItems:@[@"Bin", @"Oct", @"Dec", @"Hex"]];
    self.fromControl.selectedSegmentIndex = 2;
    self.toControl.selectedSegmentIndex = 0;
    self.fromControl.backgroundColor = [UIColor colorWithWhite:1 alpha:0.15];
    self.toControl.backgroundColor = [UIColor colorWithWhite:1 alpha:0.15];

    UIButton *swapButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [swapButton setTitle:@"Swap From/To" forState:UIControlStateNormal];
    [swapButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    swapButton.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.4].CGColor;
    swapButton.layer.borderWidth = 1;
    swapButton.layer.cornerRadius = 12;
    [swapButton addTarget:self action:@selector(swapTapped) forControlEvents:UIControlEventTouchUpInside];

    self.inputField = [[UITextField alloc] init];
    self.inputField.placeholder = @"Enter value";
    self.inputField.textColor = UIColor.whiteColor;
    self.inputField.keyboardType = UIKeyboardTypeASCIICapable;
    self.inputField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.inputField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.inputField.delegate = self;
    self.inputField.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1];
    self.inputField.layer.cornerRadius = 14;
    self.inputField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 10)];
    self.inputField.leftViewMode = UITextFieldViewModeAlways;

    self.hintLabel = [[UILabel alloc] init];
    self.hintLabel.textColor = [UIColor colorWithWhite:1 alpha:0.6];
    self.hintLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    self.hintLabel.text = @"Tip: Tap Convert to see result on next page.";

    UIButton *convertButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [convertButton setTitle:@"Convert" forState:UIControlStateNormal];
    convertButton.backgroundColor = UIColor.whiteColor;
    [convertButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    convertButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    convertButton.layer.cornerRadius = 12;
    [convertButton addTarget:self action:@selector(convertTapped) forControlEvents:UIControlEventTouchUpInside];

    UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [clearButton setTitle:@"Clear" forState:UIControlStateNormal];
    clearButton.backgroundColor = [UIColor colorWithWhite:1 alpha:0.12];
    [clearButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    clearButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    clearButton.layer.cornerRadius = 12;
    [clearButton addTarget:self action:@selector(clearTapped) forControlEvents:UIControlEventTouchUpInside];

    self.errorLabel = [[UILabel alloc] init];
    self.errorLabel.textColor = [UIColor colorWithRed:1 green:0.35 blue:0.35 alpha:1];
    self.errorLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    self.errorLabel.numberOfLines = 0;

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[title, subtitle, self.fromControl, self.toControl, swapButton, self.inputField, self.hintLabel, convertButton, clearButton, self.errorLabel]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 12;
    stack.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:stack];

    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [stack.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [stack.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:20],
        [self.inputField.heightAnchor constraintEqualToConstant:50],
        [convertButton.heightAnchor constraintEqualToConstant:50],
        [clearButton.heightAnchor constraintEqualToConstant:50],
        [swapButton.heightAnchor constraintEqualToConstant:44]
    ]];
}

- (OCBBaseType)baseTypeFromIndex:(NSInteger)index {
    switch (index) {
        case 0: return OCBBaseTypeBinary;
        case 1: return OCBBaseTypeOctal;
        case 2: return OCBBaseTypeDecimal;
        case 3: return OCBBaseTypeHexadecimal;
        default: return OCBBaseTypeDecimal;
    }
}

- (void)swapTapped {
    NSInteger temp = self.fromControl.selectedSegmentIndex;
    self.fromControl.selectedSegmentIndex = self.toControl.selectedSegmentIndex;
    self.toControl.selectedSegmentIndex = temp;
}

- (void)clearTapped {
    self.inputField.text = @"";
    self.errorLabel.text = @"";
}

- (void)convertTapped {
    OCBBaseType source = [self baseTypeFromIndex:self.fromControl.selectedSegmentIndex];
    OCBBaseType target = [self baseTypeFromIndex:self.toControl.selectedSegmentIndex];
    NSString *input = self.inputField.text ?: @"";
    NSString *result = [OCBBaseConverter convertValue:input from:source to:target];

    if (result.length == 0) {
        self.errorLabel.text = [NSString stringWithFormat:@"Invalid value for %@", [OCBBaseConverter titleForBase:source]];
        return;
    }

    self.errorLabel.text = @"";
    OCBResultViewController *resultVC = [[OCBResultViewController alloc] initWithInput:input output:result source:source target:target];
    [self.navigationController pushViewController:resultVC animated:YES];
}

@end
