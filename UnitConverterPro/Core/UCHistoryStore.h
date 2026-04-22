#import <Foundation/Foundation.h>

@class UCConversionRecord;

NS_ASSUME_NONNULL_BEGIN

@interface UCHistoryStore : NSObject

+ (instancetype)shared;
- (NSArray<UCConversionRecord *> *)allRecords;
- (void)addRecord:(UCConversionRecord *)record;
- (void)clear;

@end

NS_ASSUME_NONNULL_END
