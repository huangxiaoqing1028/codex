#import "BalanceLoader.h"
@implementation BalanceLoader { NSArray *_chapters; NSArray *_equipments; }
+ (instancetype)shared { static BalanceLoader *x; static dispatch_once_t once; dispatch_once(&once, ^{ x=[BalanceLoader new];}); return x; }
- (NSArray<NSDictionary *> *)chapters { return _chapters ?: @[]; }
- (NSArray<NSDictionary *> *)equipments { return _equipments ?: @[]; }
- (void)loadTables {
    NSBundle *b = NSBundle.mainBundle;
    NSData *cData = [NSData dataWithContentsOfFile:[b pathForResource:@"balance_chapters" ofType:@"json" inDirectory:@"Resources/Data"]];
    NSData *eData = [NSData dataWithContentsOfFile:[b pathForResource:@"balance_equipment" ofType:@"json" inDirectory:@"Resources/Data"]];
    _chapters = cData ? [NSJSONSerialization JSONObjectWithData:cData options:0 error:nil] : @[];
    _equipments = eData ? [NSJSONSerialization JSONObjectWithData:eData options:0 error:nil] : @[];
}
@end
