#import "ResumeStore.h"
#import "ResumeModel.h"
@implementation ResumeStore
+ (instancetype)shared { static ResumeStore *s; static dispatch_once_t once; dispatch_once(&once, ^{ s=[ResumeStore new];}); return s; }
- (NSString *)path { return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES).firstObject stringByAppendingPathComponent:@"resumes.json"]; }
- (NSArray<ResumeModel *> *)allResumes { NSData *d=[NSData dataWithContentsOfFile:[self path]]; if(!d){ return @[]; } NSArray *arr=[NSJSONSerialization JSONObjectWithData:d options:0 error:nil]; NSMutableArray *out=[NSMutableArray array]; for(NSDictionary *x in arr){ [out addObject:[ResumeModel fromDictionary:x]]; } return out; }
- (void)saveResume:(ResumeModel *)resume { NSMutableArray *all=[NSMutableArray arrayWithArray:[[self allResumes] valueForKey:@"toDictionary"]]; NSUInteger idx=[all indexOfObjectPassingTest:^BOOL(NSDictionary *obj, NSUInteger idx, BOOL *stop){ return [obj[@"resumeId"] isEqual:resume.resumeId]; }]; if(idx!=NSNotFound){ all[idx]=resume.toDictionary; } else { [all addObject:resume.toDictionary]; }
 NSData *d=[NSJSONSerialization dataWithJSONObject:all options:NSJSONWritingPrettyPrinted error:nil]; [d writeToFile:[self path] atomically:YES]; }
@end
