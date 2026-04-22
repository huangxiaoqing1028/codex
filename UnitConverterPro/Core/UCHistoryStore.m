#import "UCHistoryStore.h"
#import "UCConversionRecord.h"

static NSString * const kHistoryKey = @"uc.history.records";
static NSUInteger const kMaxCount = 60;

@implementation UCHistoryStore {
    NSMutableArray<UCConversionRecord *> *_records;
}

+ (instancetype)shared {
    static UCHistoryStore *store;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        store = [[UCHistoryStore alloc] initPrivate];
    });
    return store;
}

- (instancetype)init {
    NSAssert(NO, @"Use +shared");
    return nil;
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:kHistoryKey];
        NSArray *saved = @[];
        if (data != nil) {
            NSSet *classes = [NSSet setWithObjects:[NSArray class], [UCConversionRecord class], nil];
            saved = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:data error:nil] ?: @[];
        }
        _records = [saved mutableCopy];
    }
    return self;
}

- (NSArray<UCConversionRecord *> *)allRecords {
    return [_records copy];
}

- (void)addRecord:(UCConversionRecord *)record {
    [_records insertObject:record atIndex:0];
    if (_records.count > kMaxCount) {
        [_records removeLastObject];
    }
    [self persist];
}

- (void)clear {
    [_records removeAllObjects];
    [self persist];
}

- (void)persist {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:_records requiringSecureCoding:YES error:nil];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:kHistoryKey];
}

@end
