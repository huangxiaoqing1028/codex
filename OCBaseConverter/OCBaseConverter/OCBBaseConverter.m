#import "OCBBaseConverter.h"

@implementation OCBBaseConverter

+ (NSString *)titleForBase:(OCBBaseType)base {
    switch (base) {
        case OCBBaseTypeBinary: return @"Binary";
        case OCBBaseTypeOctal: return @"Octal";
        case OCBBaseTypeDecimal: return @"Decimal";
        case OCBBaseTypeHexadecimal: return @"Hex";
    }
}

+ (nullable NSString *)convertValue:(NSString *)value from:(OCBBaseType)source to:(OCBBaseType)target {
    NSString *trimmed = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) { return nil; }

    NSString *charset = @"";
    switch (source) {
        case OCBBaseTypeBinary: charset = @"01"; break;
        case OCBBaseTypeOctal: charset = @"01234567"; break;
        case OCBBaseTypeDecimal: charset = @"0123456789"; break;
        case OCBBaseTypeHexadecimal: charset = @"0123456789ABCDEFabcdef"; break;
    }

    NSCharacterSet *validSet = [NSCharacterSet characterSetWithCharactersInString:charset];
    for (NSUInteger i = 0; i < trimmed.length; i++) {
        unichar c = [trimmed characterAtIndex:i];
        if (![validSet characterIsMember:c]) {
            return nil;
        }
    }

    unsigned long long decimalValue = strtoull([trimmed UTF8String], NULL, (int)source);
    if (decimalValue == ULLONG_MAX && errno == ERANGE) {
        return nil;
    }

    if (target == OCBBaseTypeDecimal) {
        return [NSString stringWithFormat:@"%llu", decimalValue];
    }

    NSMutableString *result = [NSMutableString string];
    unsigned long long quotient = decimalValue;
    NSString *digits = @"0123456789ABCDEF";

    if (quotient == 0) {
        return @"0";
    }

    while (quotient > 0) {
        NSInteger remainder = quotient % target;
        [result insertString:[digits substringWithRange:NSMakeRange(remainder, 1)] atIndex:0];
        quotient /= target;
    }
    return result;
}

@end
