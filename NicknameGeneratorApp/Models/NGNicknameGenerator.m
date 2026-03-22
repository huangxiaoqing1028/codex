#import "NGNicknameGenerator.h"

static NSString * const kNGRecentNicknamesKey = @"ng_recent_nicknames";
static NSString * const kNGFavoriteNicknamesKey = @"ng_favorite_nicknames";

@interface NGNicknameGenerator ()
@property (nonatomic, strong) NSArray<NSString *> *adjectives;
@property (nonatomic, strong) NSArray<NSString *> *nouns;
@property (nonatomic, strong) NSArray<NSString *> *cyberTokens;
@property (nonatomic, strong) NSMutableArray<NSString *> *mutableRecentNicknames;
@property (nonatomic, strong) NSMutableArray<NSString *> *mutableFavoriteNicknames;
@end

@implementation NGNicknameGenerator

- (instancetype)init {
    self = [super init];
    if (self) {
        _adjectives = @[@"星辰", @"风语", @"暮色", @"深海", @"薄雾", @"琥珀", @"隐刃", @"霓虹", @"晴岚", @"墨羽"];
        _nouns = @[@"旅人", @"猎手", @"信使", @"编织者", @"影子", @"行者", @"指挥官", @"吟游", @"观察员", @"漫游者"];
        _cyberTokens = @[@"404", @"Zero", @"Nova", @"Pulse", @"Echo", @"X", @"Byte", @"AI", @"Flux", @"V"];

        NSArray *savedRecent = [[NSUserDefaults standardUserDefaults] objectForKey:kNGRecentNicknamesKey];
        NSArray *savedFavorites = [[NSUserDefaults standardUserDefaults] objectForKey:kNGFavoriteNicknamesKey];

        _mutableRecentNicknames = savedRecent ? [savedRecent mutableCopy] : [NSMutableArray array];
        _mutableFavoriteNicknames = savedFavorites ? [savedFavorites mutableCopy] : [NSMutableArray array];
    }
    return self;
}

- (NSArray<NSString *> *)recentNicknames {
    return [self.mutableRecentNicknames copy];
}

- (NSArray<NSString *> *)favoriteNicknames {
    return [self.mutableFavoriteNicknames copy];
}

- (NSString *)generateNicknameWithStyle:(NSString *)style includeNumber:(BOOL)includeNumber {
    NSString *nickname;
    if ([style isEqualToString:@"赛博"]) {
        nickname = [NSString stringWithFormat:@"%@_%@%@",
                    [self randomItemFrom:self.adjectives],
                    [self randomItemFrom:self.cyberTokens],
                    [self randomItemFrom:self.nouns]];
    } else if ([style isEqualToString:@"古风"]) {
        nickname = [NSString stringWithFormat:@"%@·%@",
                    [self randomItemFrom:self.adjectives],
                    [self randomItemFrom:self.nouns]];
    } else {
        nickname = [NSString stringWithFormat:@"%@%@",
                    [self randomItemFrom:self.adjectives],
                    [self randomItemFrom:self.nouns]];
    }

    if (includeNumber) {
        NSUInteger number = arc4random_uniform(9000) + 1000;
        nickname = [nickname stringByAppendingFormat:@"%lu", (unsigned long)number];
    }

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

    while (self.mutableRecentNicknames.count > 12) {
        [self.mutableRecentNicknames removeLastObject];
    }

    [self persist];
}

- (void)persist {
    [[NSUserDefaults standardUserDefaults] setObject:self.mutableRecentNicknames forKey:kNGRecentNicknamesKey];
    [[NSUserDefaults standardUserDefaults] setObject:self.mutableFavoriteNicknames forKey:kNGFavoriteNicknamesKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
