#import "RSResumeStore.h"
#import "RSResume.h"

static NSString * const kRSResumesKey = @"kRSResumesKey";

@implementation RSResumeStore

+ (instancetype)shared {
    static RSResumeStore *store;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ store = [[RSResumeStore alloc] init]; });
    return store;
}

- (NSArray<RSResume *> *)allResumes {
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:kRSResumesKey];
    if (!data) { return @[]; }
    NSError *error = nil;
    NSSet *classes = [NSSet setWithArray:@[[NSArray class], [RSResume class]]];
    NSArray<RSResume *> *items = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:data error:&error];
    return error ? @[] : (items ?: @[]);
}

- (void)saveResume:(RSResume *)resume {
    NSMutableArray<RSResume *> *items = [[self allResumes] mutableCopy];
    NSUInteger idx = [items indexOfObjectPassingTest:^BOOL(RSResume *obj, NSUInteger idx, BOOL *stop) {
        return [obj.resumeId isEqualToString:resume.resumeId];
    }];
    resume.updatedAt = [NSDate date];
    if (idx != NSNotFound) {
        items[idx] = resume;
    } else {
        [items insertObject:resume atIndex:0];
    }
    NSError *error = nil;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:items requiringSecureCoding:YES error:&error];
    if (!error && data) {
        [[NSUserDefaults standardUserDefaults] setObject:data forKey:kRSResumesKey];
    }
}

@end
