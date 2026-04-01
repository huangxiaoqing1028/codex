#import "AppDelegate.h"

@interface BaseConverterViewController : UIViewController <UITextFieldDelegate>
@property (nonatomic, strong) CAGradientLayer *backgroundGradient;
@property (nonatomic, strong) UIView *glassCard;
@property (nonatomic, strong) UITextField *inputField;
@property (nonatomic, strong) UISegmentedControl *baseSelector;
@property (nonatomic, strong) UIStackView *resultsStack;
@property (nonatomic, strong) NSArray<NSNumber *> *baseOrder;
@property (nonatomic, strong) NSDictionary<NSNumber *, UILabel *> *resultLabels;
@end

@implementation BaseConverterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"BaseFlow";
    self.baseOrder = @[@2, @8, @10, @16];

    [self setupBackground];
    [self setupLayout];
    [self updateResults];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.backgroundGradient.frame = self.view.bounds;
}

- (void)setupBackground {
    self.view.backgroundColor = [UIColor blackColor];
    self.backgroundGradient = [CAGradientLayer layer];
    self.backgroundGradient.colors = @[
        (__bridge id)[UIColor colorWithRed:0.09 green:0.11 blue:0.23 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:0.20 green:0.10 blue:0.32 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:0.06 green:0.30 blue:0.41 alpha:1.0].CGColor
    ];
    self.backgroundGradient.startPoint = CGPointMake(0.0, 0.0);
    self.backgroundGradient.endPoint = CGPointMake(1.0, 1.0);
    [self.view.layer addSublayer:self.backgroundGradient];
}

- (void)setupLayout {
    UIView *contentView = [[UIView alloc] init];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:contentView];

    UILabel *headline = [[UILabel alloc] init];
    headline.translatesAutoresizingMaskIntoConstraints = NO;
    headline.text = @"Convert Numbers Beautifully";
    headline.textColor = [UIColor colorWithWhite:1.0 alpha:0.95];
    headline.font = [UIFont systemFontOfSize:31 weight:UIFontWeightSemibold];
    headline.numberOfLines = 0;

    UILabel *subhead = [[UILabel alloc] init];
    subhead.translatesAutoresizingMaskIntoConstraints = NO;
    subhead.text = @"Binary · Octal · Decimal · Hex\nPremium-grade UI, instant conversion.";
    subhead.textColor = [UIColor colorWithWhite:1.0 alpha:0.72];
    subhead.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    subhead.numberOfLines = 0;

    self.glassCard = [[UIView alloc] init];
    self.glassCard.translatesAutoresizingMaskIntoConstraints = NO;
    self.glassCard.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.14];
    self.glassCard.layer.cornerRadius = 24.0;
    self.glassCard.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.35].CGColor;
    self.glassCard.layer.borderWidth = 1.0;
    self.glassCard.layer.shadowColor = [UIColor blackColor].CGColor;
    self.glassCard.layer.shadowOpacity = 0.25;
    self.glassCard.layer.shadowRadius = 24;
    self.glassCard.layer.shadowOffset = CGSizeMake(0, 12);

    UIVisualEffectView *blur = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark]];
    blur.frame = self.glassCard.bounds;
    blur.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    blur.layer.cornerRadius = 24.0;
    blur.clipsToBounds = YES;
    [self.glassCard addSubview:blur];

    UIView *cardContent = [[UIView alloc] init];
    cardContent.translatesAutoresizingMaskIntoConstraints = NO;
    [self.glassCard addSubview:cardContent];

    UILabel *inputTitle = [[UILabel alloc] init];
    inputTitle.translatesAutoresizingMaskIntoConstraints = NO;
    inputTitle.text = @"Input Number";
    inputTitle.textColor = [UIColor colorWithWhite:1.0 alpha:0.88];
    inputTitle.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];

    self.inputField = [[UITextField alloc] init];
    self.inputField.translatesAutoresizingMaskIntoConstraints = NO;
    self.inputField.borderStyle = UITextBorderStyleNone;
    self.inputField.delegate = self;
    self.inputField.keyboardType = UIKeyboardTypeASCIICapable;
    self.inputField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
    self.inputField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.inputField.smartDashesType = UITextSmartDashesTypeNo;
    self.inputField.smartQuotesType = UITextSmartQuotesTypeNo;
    self.inputField.spellCheckingType = UITextSpellCheckingTypeNo;
    self.inputField.placeholder = @"Type value";
    self.inputField.text = @"255";
    self.inputField.textColor = [UIColor whiteColor];
    self.inputField.font = [UIFont monospacedDigitSystemFontOfSize:24 weight:UIFontWeightMedium];
    self.inputField.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.22];
    self.inputField.layer.cornerRadius = 14;
    self.inputField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 14, 10)];
    self.inputField.leftViewMode = UITextFieldViewModeAlways;
    [self.inputField addTarget:self action:@selector(updateResults) forControlEvents:UIControlEventEditingChanged];

    self.baseSelector = [[UISegmentedControl alloc] initWithItems:@[@"BIN", @"OCT", @"DEC", @"HEX"]];
    self.baseSelector.translatesAutoresizingMaskIntoConstraints = NO;
    self.baseSelector.selectedSegmentIndex = 2;
    self.baseSelector.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.2];
    self.baseSelector.selectedSegmentTintColor = [UIColor colorWithRed:0.40 green:0.84 blue:0.98 alpha:0.85];
    [self.baseSelector setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:1.0 alpha:0.82], NSFontAttributeName: [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold]} forState:UIControlStateNormal];
    [self.baseSelector setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0.1 alpha:1.0], NSFontAttributeName: [UIFont systemFontOfSize:13 weight:UIFontWeightBold]} forState:UIControlStateSelected];
    [self.baseSelector addTarget:self action:@selector(updateResults) forControlEvents:UIControlEventValueChanged];

    self.resultsStack = [[UIStackView alloc] init];
    self.resultsStack.translatesAutoresizingMaskIntoConstraints = NO;
    self.resultsStack.axis = UILayoutConstraintAxisVertical;
    self.resultsStack.spacing = 10;

    NSMutableDictionary<NSNumber *, UILabel *> *labels = [NSMutableDictionary dictionary];
    for (NSNumber *base in self.baseOrder) {
        UIView *row = [self resultRowForBase:base labelStore:labels];
        [self.resultsStack addArrangedSubview:row];
    }
    self.resultLabels = labels;

    [cardContent addSubview:inputTitle];
    [cardContent addSubview:self.inputField];
    [cardContent addSubview:self.baseSelector];
    [cardContent addSubview:self.resultsStack];

    [contentView addSubview:headline];
    [contentView addSubview:subhead];
    [contentView addSubview:self.glassCard];

    UILayoutGuide *guide = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [contentView.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor constant:20],
        [contentView.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor constant:-20],
        [contentView.topAnchor constraintEqualToAnchor:guide.topAnchor constant:18],
        [contentView.bottomAnchor constraintLessThanOrEqualToAnchor:guide.bottomAnchor constant:-16],

        [headline.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor],
        [headline.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor],
        [headline.topAnchor constraintEqualToAnchor:contentView.topAnchor constant:8],

        [subhead.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor],
        [subhead.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor],
        [subhead.topAnchor constraintEqualToAnchor:headline.bottomAnchor constant:8],

        [self.glassCard.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor],
        [self.glassCard.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor],
        [self.glassCard.topAnchor constraintEqualToAnchor:subhead.bottomAnchor constant:20],

        [cardContent.leadingAnchor constraintEqualToAnchor:self.glassCard.leadingAnchor constant:18],
        [cardContent.trailingAnchor constraintEqualToAnchor:self.glassCard.trailingAnchor constant:-18],
        [cardContent.topAnchor constraintEqualToAnchor:self.glassCard.topAnchor constant:18],
        [cardContent.bottomAnchor constraintEqualToAnchor:self.glassCard.bottomAnchor constant:-18],

        [inputTitle.leadingAnchor constraintEqualToAnchor:cardContent.leadingAnchor],
        [inputTitle.trailingAnchor constraintEqualToAnchor:cardContent.trailingAnchor],
        [inputTitle.topAnchor constraintEqualToAnchor:cardContent.topAnchor],

        [self.inputField.leadingAnchor constraintEqualToAnchor:cardContent.leadingAnchor],
        [self.inputField.trailingAnchor constraintEqualToAnchor:cardContent.trailingAnchor],
        [self.inputField.topAnchor constraintEqualToAnchor:inputTitle.bottomAnchor constant:8],
        [self.inputField.heightAnchor constraintEqualToConstant:56],

        [self.baseSelector.leadingAnchor constraintEqualToAnchor:cardContent.leadingAnchor],
        [self.baseSelector.trailingAnchor constraintEqualToAnchor:cardContent.trailingAnchor],
        [self.baseSelector.topAnchor constraintEqualToAnchor:self.inputField.bottomAnchor constant:12],

        [self.resultsStack.leadingAnchor constraintEqualToAnchor:cardContent.leadingAnchor],
        [self.resultsStack.trailingAnchor constraintEqualToAnchor:cardContent.trailingAnchor],
        [self.resultsStack.topAnchor constraintEqualToAnchor:self.baseSelector.bottomAnchor constant:16],
        [self.resultsStack.bottomAnchor constraintEqualToAnchor:cardContent.bottomAnchor],
    ]];
}

- (UIView *)resultRowForBase:(NSNumber *)base labelStore:(NSMutableDictionary<NSNumber *, UILabel *> *)labelStore {
    UIView *row = [[UIView alloc] init];
    row.translatesAutoresizingMaskIntoConstraints = NO;
    row.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.20];
    row.layer.cornerRadius = 12;

    UILabel *title = [[UILabel alloc] init];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = [self titleForBase:base.integerValue];
    title.textColor = [UIColor colorWithWhite:1.0 alpha:0.76];
    title.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];

    UILabel *valueLabel = [[UILabel alloc] init];
    valueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    valueLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.98];
    valueLabel.font = [UIFont monospacedDigitSystemFontOfSize:18 weight:UIFontWeightSemibold];
    valueLabel.adjustsFontSizeToFitWidth = YES;
    valueLabel.minimumScaleFactor = 0.7;

    [row addSubview:title];
    [row addSubview:valueLabel];

    [NSLayoutConstraint activateConstraints:@[
        [row.heightAnchor constraintEqualToConstant:68],
        [title.leadingAnchor constraintEqualToAnchor:row.leadingAnchor constant:14],
        [title.trailingAnchor constraintEqualToAnchor:row.trailingAnchor constant:-14],
        [title.topAnchor constraintEqualToAnchor:row.topAnchor constant:10],
        [valueLabel.leadingAnchor constraintEqualToAnchor:row.leadingAnchor constant:14],
        [valueLabel.trailingAnchor constraintEqualToAnchor:row.trailingAnchor constant:-14],
        [valueLabel.bottomAnchor constraintEqualToAnchor:row.bottomAnchor constant:-10],
    ]];

    labelStore[base] = valueLabel;
    return row;
}

- (NSString *)titleForBase:(NSInteger)base {
    switch (base) {
        case 2: return @"Binary (Base 2)";
        case 8: return @"Octal (Base 8)";
        case 10: return @"Decimal (Base 10)";
        case 16: return @"Hex (Base 16)";
        default: return @"Unknown";
    }
}

- (NSString *)sanitize:(NSString *)text forBase:(NSInteger)base {
    NSMutableString *result = [NSMutableString string];
    NSCharacterSet *allowed;
    switch (base) {
        case 2:
            allowed = [NSCharacterSet characterSetWithCharactersInString:@"01"];
            break;
        case 8:
            allowed = [NSCharacterSet characterSetWithCharactersInString:@"01234567"];
            break;
        case 10:
            allowed = [NSCharacterSet decimalDigitCharacterSet];
            break;
        case 16:
            allowed = [NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdefABCDEF"];
            break;
        default:
            allowed = [NSCharacterSet decimalDigitCharacterSet];
            break;
    }

    for (NSUInteger idx = 0; idx < text.length; idx++) {
        unichar c = [text characterAtIndex:idx];
        if ([allowed characterIsMember:c]) {
            [result appendFormat:@"%C", c];
        }
    }
    return result;
}

- (void)updateResults {
    NSInteger sourceBase = [self.baseOrder[self.baseSelector.selectedSegmentIndex] integerValue];
    NSString *rawInput = self.inputField.text ?: @"";
    NSString *sanitized = [self sanitize:rawInput forBase:sourceBase];

    if (![rawInput isEqualToString:sanitized]) {
        self.inputField.text = sanitized;
    }

    if (sanitized.length == 0) {
        for (NSNumber *base in self.baseOrder) {
            self.resultLabels[base].text = @"—";
        }
        return;
    }

    unsigned long long decimalValue = strtoull(sanitized.UTF8String, NULL, (int)sourceBase);

    for (NSNumber *base in self.baseOrder) {
        NSInteger targetBase = base.integerValue;
        UILabel *label = self.resultLabels[base];
        switch (targetBase) {
            case 2:
                label.text = [self stringFromValue:decimalValue radix:2 uppercase:NO];
                break;
            case 8:
                label.text = [NSString stringWithFormat:@"%llo", decimalValue];
                break;
            case 10:
                label.text = [NSString stringWithFormat:@"%llu", decimalValue];
                break;
            case 16:
                label.text = [[NSString stringWithFormat:@"%llX", decimalValue] uppercaseString];
                break;
            default:
                label.text = @"—";
                break;
        }
    }
}

- (NSString *)stringFromValue:(unsigned long long)value radix:(NSUInteger)radix uppercase:(BOOL)uppercase {
    if (value == 0) {
        return @"0";
    }

    NSString *digits = uppercase ? @"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ" : @"0123456789abcdefghijklmnopqrstuvwxyz";
    NSMutableString *result = [NSMutableString string];
    unsigned long long current = value;

    while (current > 0) {
        NSUInteger remainder = (NSUInteger)(current % radix);
        unichar ch = [digits characterAtIndex:remainder];
        [result insertString:[NSString stringWithFormat:@"%C", ch] atIndex:0];
        current /= radix;
    }

    return result;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];

    BaseConverterViewController *rootVC = [BaseConverterViewController new];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:rootVC];
    nav.navigationBar.prefersLargeTitles = YES;
    nav.navigationBar.tintColor = [UIColor whiteColor];
    nav.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    nav.navigationBar.largeTitleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};

    if (@available(iOS 15.0, *)) {
        UINavigationBarAppearance *appearance = [UINavigationBarAppearance new];
        [appearance configureWithTransparentBackground];
        appearance.backgroundColor = [UIColor clearColor];
        appearance.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
        appearance.largeTitleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
        nav.navigationBar.standardAppearance = appearance;
        nav.navigationBar.scrollEdgeAppearance = appearance;
    }

    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
