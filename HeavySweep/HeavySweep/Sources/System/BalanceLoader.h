#import <Foundation/Foundation.h>
@interface BalanceLoader : NSObject
+ (instancetype)shared;
@property (nonatomic, strong, readonly) NSArray<NSDictionary *> *chapters;
@property (nonatomic, strong, readonly) NSArray<NSDictionary *> *equipments;
- (void)loadTables;
@end
