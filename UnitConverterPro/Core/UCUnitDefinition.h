#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UCUnitDefinition : NSObject

@property (nonatomic, copy, readonly) NSString *identifier;
@property (nonatomic, copy, readonly) NSString *displayName;
@property (nonatomic, copy, readonly) NSString *symbol;
@property (nonatomic, assign, readonly) double coefficient;
@property (nonatomic, assign, readonly) double bias;

- (instancetype)initWithIdentifier:(NSString *)identifier
                       displayName:(NSString *)displayName
                            symbol:(NSString *)symbol
                       coefficient:(double)coefficient
                              bias:(double)bias;

@end

NS_ASSUME_NONNULL_END
