#import "UCConversionEngine.h"
#import "UCUnitCategory.h"
#import "UCUnitDefinition.h"

@implementation UCConversionEngine {
    NSArray<UCUnitCategory *> *_categories;
}

+ (instancetype)shared {
    static UCConversionEngine *engine;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        engine = [[UCConversionEngine alloc] initPrivate];
    });
    return engine;
}

- (instancetype)init {
    NSAssert(NO, @"Use +shared");
    return nil;
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        _categories = [self buildCategories];
    }
    return self;
}

- (NSArray<UCUnitCategory *> *)allCategories {
    return _categories;
}

- (double)convertValue:(double)value fromUnit:(UCUnitDefinition *)fromUnit toUnit:(UCUnitDefinition *)toUnit {
    double baseValue = value * fromUnit.coefficient + fromUnit.bias;
    return (baseValue - toUnit.bias) / toUnit.coefficient;
}

- (NSArray<UCUnitCategory *> *)buildCategories {
    UCUnitCategory *length = [[UCUnitCategory alloc] initWithIdentifier:@"length"
                                                            displayName:@"长度"
                                                                  units:@[
        [[UCUnitDefinition alloc] initWithIdentifier:@"meter" displayName:@"米" symbol:@"m" coefficient:1.0 bias:0.0],
        [[UCUnitDefinition alloc] initWithIdentifier:@"kilometer" displayName:@"千米" symbol:@"km" coefficient:1000.0 bias:0.0],
        [[UCUnitDefinition alloc] initWithIdentifier:@"foot" displayName:@"英尺" symbol:@"ft" coefficient:0.3048 bias:0.0],
        [[UCUnitDefinition alloc] initWithIdentifier:@"inch" displayName:@"英寸" symbol:@"in" coefficient:0.0254 bias:0.0],
        [[UCUnitDefinition alloc] initWithIdentifier:@"mile" displayName:@"英里" symbol:@"mi" coefficient:1609.344 bias:0.0]
    ] themeColorHex:@"#5B8CFF"];

    UCUnitCategory *weight = [[UCUnitCategory alloc] initWithIdentifier:@"weight"
                                                            displayName:@"重量"
                                                                  units:@[
        [[UCUnitDefinition alloc] initWithIdentifier:@"kg" displayName:@"千克" symbol:@"kg" coefficient:1.0 bias:0.0],
        [[UCUnitDefinition alloc] initWithIdentifier:@"g" displayName:@"克" symbol:@"g" coefficient:0.001 bias:0.0],
        [[UCUnitDefinition alloc] initWithIdentifier:@"lb" displayName:@"磅" symbol:@"lb" coefficient:0.45359237 bias:0.0],
        [[UCUnitDefinition alloc] initWithIdentifier:@"oz" displayName:@"盎司" symbol:@"oz" coefficient:0.028349523125 bias:0.0]
    ] themeColorHex:@"#38C793"];

    UCUnitCategory *temperature = [[UCUnitCategory alloc] initWithIdentifier:@"temperature"
                                                                  displayName:@"温度"
                                                                        units:@[
        [[UCUnitDefinition alloc] initWithIdentifier:@"celsius" displayName:@"摄氏度" symbol:@"℃" coefficient:1.0 bias:273.15],
        [[UCUnitDefinition alloc] initWithIdentifier:@"kelvin" displayName:@"开尔文" symbol:@"K" coefficient:1.0 bias:0.0],
        [[UCUnitDefinition alloc] initWithIdentifier:@"fahrenheit" displayName:@"华氏度" symbol:@"℉" coefficient:5.0/9.0 bias:255.3722222222]
    ] themeColorHex:@"#F58D3D"];

    UCUnitCategory *volume = [[UCUnitCategory alloc] initWithIdentifier:@"volume"
                                                            displayName:@"体积"
                                                                  units:@[
        [[UCUnitDefinition alloc] initWithIdentifier:@"liter" displayName:@"升" symbol:@"L" coefficient:1.0 bias:0.0],
        [[UCUnitDefinition alloc] initWithIdentifier:@"milliliter" displayName:@"毫升" symbol:@"mL" coefficient:0.001 bias:0.0],
        [[UCUnitDefinition alloc] initWithIdentifier:@"gallon" displayName:@"美制加仑" symbol:@"gal" coefficient:3.78541 bias:0.0],
        [[UCUnitDefinition alloc] initWithIdentifier:@"cup" displayName:@"杯" symbol:@"cup" coefficient:0.236588 bias:0.0]
    ] themeColorHex:@"#A36CFF"];

    return @[length, weight, temperature, volume];
}

@end
