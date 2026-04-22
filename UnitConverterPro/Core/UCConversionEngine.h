#import <Foundation/Foundation.h>

@class UCUnitCategory;
@class UCUnitDefinition;

NS_ASSUME_NONNULL_BEGIN

@interface UCConversionEngine : NSObject

+ (instancetype)shared;
- (NSArray<UCUnitCategory *> *)allCategories;
- (double)convertValue:(double)value fromUnit:(UCUnitDefinition *)fromUnit toUnit:(UCUnitDefinition *)toUnit;

@end

NS_ASSUME_NONNULL_END
