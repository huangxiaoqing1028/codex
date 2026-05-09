#import "EquipmentSystem.h"
@implementation EquipmentSystem
+ (instancetype)shared { static EquipmentSystem *e; static dispatch_once_t once; dispatch_once(&once, ^{ e=[EquipmentSystem new]; e.equipped=[NSMutableDictionary dictionary];}); return e; }
- (NSDictionary *)rollEquipmentFromTemplate:(NSDictionary *)tpl {
    NSArray *pool = tpl[@"affixPool"] ?: @[];
    NSString *affix = pool.count ? pool[arc4random_uniform((uint32_t)pool.count)] : @"none";
    NSInteger roll = 5 + arc4random_uniform(16);
    return @{@"equipId":tpl[@"equipId"]?:@"unknown", @"name":tpl[@"name"]?:@"装备", @"affix":affix, @"roll":@(roll)};
}
- (NSInteger)totalPower { __block NSInteger p=0; [self.equipped enumerateKeysAndObjectsUsingBlock:^(NSString *k, NSDictionary *obj, BOOL *stop){ p += [obj[@"roll"] integerValue]*3; }]; return p; }
@end
