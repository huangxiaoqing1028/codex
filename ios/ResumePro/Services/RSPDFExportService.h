#import <Foundation/Foundation.h>
@class RSResume;

NS_ASSUME_NONNULL_BEGIN

@interface RSPDFExportService : NSObject
- (NSURL * _Nullable)exportResume:(RSResume *)resume error:(NSError **)error;
@end

NS_ASSUME_NONNULL_END
