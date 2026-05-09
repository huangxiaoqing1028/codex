#import <Foundation/Foundation.h>
@interface EquipmentSystem : NSObject
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDictionary *> *equipped;
+ (instancetype)shared;
- (NSDictionary *)rollEquipmentFromTemplate:(NSDictionary *)tpl;
- (NSInteger)totalPower;
@end
