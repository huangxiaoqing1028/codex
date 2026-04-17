#import <Foundation/Foundation.h>
@class RSResume;

NS_ASSUME_NONNULL_BEGIN

@interface RSResumeStore : NSObject
+ (instancetype)shared;
- (NSArray<RSResume *> *)allResumes;
- (void)saveResume:(RSResume *)resume;
@end

NS_ASSUME_NONNULL_END
