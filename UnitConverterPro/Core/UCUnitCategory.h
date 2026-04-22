#import <Foundation/Foundation.h>

@class UCUnitDefinition;

NS_ASSUME_NONNULL_BEGIN

@interface UCUnitCategory : NSObject

@property (nonatomic, copy, readonly) NSString *identifier;
@property (nonatomic, copy, readonly) NSString *displayName;
@property (nonatomic, copy, readonly) NSArray<UCUnitDefinition *> *units;
@property (nonatomic, copy, readonly) NSString *themeColorHex;

- (instancetype)initWithIdentifier:(NSString *)identifier
                       displayName:(NSString *)displayName
                             units:(NSArray<UCUnitDefinition *> *)units
                     themeColorHex:(NSString *)themeColorHex;

@end

NS_ASSUME_NONNULL_END
