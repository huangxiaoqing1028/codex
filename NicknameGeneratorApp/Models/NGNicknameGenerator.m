#import "NGNicknameGenerator.h"

NSString * const NGNicknameDataDidChangeNotification = @"ng_nickname_data_changed";
NSString * const NGNicknameSettingDidChangeNotification = @"ng_nickname_setting_changed";

static NSString * const kNGRecentNicknamesKey = @"ng_recent_nicknames";
static NSString * const kNGFavoriteNicknamesKey = @"ng_favorite_nicknames";
static NSString * const kNGDefaultNumberKey = @"ng_default_number_enabled";
static NSString * const kNGLatestNicknameKey = @"ng_latest_nickname";

@interface NGNicknameGenerator ()
@property (nonatomic, strong) NSArray<NSString *> *prettyPool;
@property (nonatomic, strong) NSArray<NSString *> *ancientPool;
@property (nonatomic, strong) NSArray<NSString *> *cyberPool;
@property (nonatomic, strong) NSMutableArray<NSString *> *mutableRecentNicknames;
@property (nonatomic, strong) NSMutableArray<NSString *> *mutableFavoriteNicknames;
@property (nonatomic, copy) NSString *latestNicknameStorage;
@end

@implementation NGNicknameGenerator

+ (instancetype)shared {
    static NGNicknameGenerator *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NGNicknameGenerator alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSArray<NSString *> *prefixes = @[@"星", @"云", @"月", @"岚", @"雾", @"海", @"森", @"雪", @"霜", @"风",
                                          @"光", @"影", @"梦", @"夜", @"晨", @"暮", @"晴", @"墨", @"青", @"白",
                                          @"赤", @"紫", @"玄", @"幽", @"璃", @"羽", @"潮", @"焰", @"雷", @"沙",
                                          @"川", @"舟", @"虹", @"砂", @"花", @"竹", @"松", @"鹿", @"鲸", @"萤"];

        NSArray<NSString *> *roots = @[@"旅人", @"行者", @"信使", @"猎手", @"吟游", @"星使", @"骑士", @"守望", @"诗人", @"漫游者",
                                       @"编织者", @"拾光者", @"冒险家", @"观察员", @"引路人", @"逐梦者", @"远航者", @"风铃", @"笺客", @"潮汐",
                                       @"微光", @"听雨", @"寻川", @"夜航", @"南歌"];

        _prettyPool = [self buildPoolWithPrefixes:prefixes roots:roots format:@"%@%@"];
        _ancientPool = [self buildPoolWithPrefixes:prefixes roots:roots format:@"%@·%@"];
        _cyberPool = [self buildPoolWithPrefixes:prefixes roots:roots format:@"%@_%@"];

        NSArray *savedRecent = [[NSUserDefaults standardUserDefaults] objectForKey:kNGRecentNicknamesKey];
        NSArray *savedFavorites = [[NSUserDefaults standardUserDefaults] objectForKey:kNGFavoriteNicknamesKey];

        _mutableRecentNicknames = savedRecent ? [savedRecent mutableCopy] : [NSMutableArray array];
        _mutableFavoriteNicknames = savedFavorites ? [savedFavorites mutableCopy] : [NSMutableArray array];
        _latestNicknameStorage = [[NSUserDefaults standardUserDefaults] objectForKey:kNGLatestNicknameKey] ?: @"";
        _defaultIncludeNumber = [[NSUserDefaults standardUserDefaults] boolForKey:kNGDefaultNumberKey];
    }
    return self;
}

- (NSArray<NSString *> *)buildPoolWithPrefixes:(NSArray<NSString *> *)prefixes roots:(NSArray<NSString *> *)roots format:(NSString *)format {
    NSMutableArray<NSString *> *pool = [NSMutableArray arrayWithCapacity:prefixes.count * roots.count];
    for (NSString *prefix in prefixes) {
        for (NSString *root in roots) {
            [pool addObject:[NSString stringWithFormat:format, prefix, root]];
        }
    }
    return [pool copy];
}

- (NSArray<NSString *> *)recentNicknames {
    return [self.mutableRecentNicknames copy];
}

- (NSArray<NSString *> *)favoriteNicknames {
    return [self.mutableFavoriteNicknames copy];
}

- (NSUInteger)libraryCount {
    return self.prettyPool.count;
}

- (NSString *)latestNickname {
    return self.latestNicknameStorage;
}

- (void)setDefaultIncludeNumber:(BOOL)defaultIncludeNumber {
    _defaultIncludeNumber = defaultIncludeNumber;
    [[NSUserDefaults standardUserDefaults] setBool:defaultIncludeNumber forKey:kNGDefaultNumberKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:NGNicknameSettingDidChangeNotification object:nil];
}

- (NSString *)generateNicknameWithStyle:(NSString *)style includeNumber:(BOOL)includeNumber {
    NSArray<NSString *> *pool = self.prettyPool;
    if ([style isEqualToString:@"古风"]) {
        pool = self.ancientPool;
    } else if ([style isEqualToString:@"赛博"]) {
        pool = self.cyberPool;
    }

    NSString *nickname = [self randomItemFrom:pool];

    if ([style isEqualToString:@"赛博"]) {
        NSArray<NSString *> *tokens = @[@"404", @"Zero", @"Nova", @"Pulse", @"Echo", @"X", @"Byte", @"AI", @"Flux", @"V"];
        nickname = [NSString stringWithFormat:@"%@%@", nickname, [self randomItemFrom:tokens]];
    }

    if (includeNumber) {
        NSUInteger number = arc4random_uniform(9000) + 1000;
        nickname = [nickname stringByAppendingFormat:@"%lu", (unsigned long)number];
    }

    self.latestNicknameStorage = nickname;
    [self pushRecent:nickname];
    return nickname;
}

- (void)toggleFavorite:(NSString *)nickname {
    if ([self.mutableFavoriteNicknames containsObject:nickname]) {
        [self.mutableFavoriteNicknames removeObject:nickname];
    } else {
        [self.mutableFavoriteNicknames insertObject:nickname atIndex:0];
    }

    [self persist];
}

- (BOOL)isFavorite:(NSString *)nickname {
    return [self.mutableFavoriteNicknames containsObject:nickname];
}

- (void)clearAllData {
    [self.mutableRecentNicknames removeAllObjects];
    [self.mutableFavoriteNicknames removeAllObjects];
    [self persist];
}

- (NSString *)randomItemFrom:(NSArray<NSString *> *)collection {
    if (collection.count == 0) {
        return @"";
    }
    u_int32_t index = arc4random_uniform((u_int32_t)collection.count);
    return collection[index];
}

- (void)pushRecent:(NSString *)nickname {
    [self.mutableRecentNicknames removeObject:nickname];
    [self.mutableRecentNicknames insertObject:nickname atIndex:0];

    while (self.mutableRecentNicknames.count > 20) {
        [self.mutableRecentNicknames removeLastObject];
    }

    [self persist];
}

- (void)persist {
    [[NSUserDefaults standardUserDefaults] setObject:self.mutableRecentNicknames forKey:kNGRecentNicknamesKey];
    [[NSUserDefaults standardUserDefaults] setObject:self.mutableFavoriteNicknames forKey:kNGFavoriteNicknamesKey];
    [[NSUserDefaults standardUserDefaults] setObject:self.latestNicknameStorage forKey:kNGLatestNicknameKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:NGNicknameDataDidChangeNotification object:nil];
}

@end
