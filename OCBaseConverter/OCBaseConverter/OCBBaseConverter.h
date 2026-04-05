#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, OCBBaseType) {
    OCBBaseTypeBinary = 2,
    OCBBaseTypeOctal = 8,
    OCBBaseTypeDecimal = 10,
    OCBBaseTypeHexadecimal = 16
};

@interface OCBBaseConverter : NSObject
+ (nullable NSString *)convertValue:(NSString *)value from:(OCBBaseType)source to:(OCBBaseType)target;
+ (NSString *)titleForBase:(OCBBaseType)base;
@end
