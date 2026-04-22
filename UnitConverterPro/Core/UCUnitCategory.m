#import "UCUnitCategory.h"

@implementation UCUnitCategory

- (instancetype)initWithIdentifier:(NSString *)identifier
                       displayName:(NSString *)displayName
                             units:(NSArray *)units
                     themeColorHex:(NSString *)themeColorHex {
    self = [super init];
    if (self) {
        _identifier = [identifier copy];
        _displayName = [displayName copy];
        _units = [units copy];
        _themeColorHex = [themeColorHex copy];
    }
    return self;
}

@end
