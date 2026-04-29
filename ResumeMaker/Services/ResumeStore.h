#import <Foundation/Foundation.h>
@class ResumeModel;
@interface ResumeStore : NSObject
+ (instancetype)shared;
- (NSArray<ResumeModel *> *)allResumes;
- (void)saveResume:(ResumeModel *)resume;
@end
