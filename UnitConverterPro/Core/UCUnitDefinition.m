#import "UCUnitDefinition.h"

@implementation UCUnitDefinition

- (instancetype)initWithIdentifier:(NSString *)identifier
                       displayName:(NSString *)displayName
                            symbol:(NSString *)symbol
                       coefficient:(double)coefficient
                              bias:(double)bias {
    self = [super init];
    if (self) {
        _identifier = [identifier copy];
        _displayName = [displayName copy];
        _symbol = [symbol copy];
        _coefficient = coefficient;
        _bias = bias;
    }
    return self;
}

@end
