#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const NGNicknameDataDidChangeNotification;
extern NSString * const NGNicknameSettingDidChangeNotification;

@interface NGNicknameGenerator : NSObject

@property (nonatomic, readonly) NSArray<NSString *> *recentNicknames;
@property (nonatomic, readonly) NSArray<NSString *> *favoriteNicknames;
@property (nonatomic, copy, readonly) NSString *latestNickname;
@property (nonatomic, readonly) NSUInteger libraryCount;
@property (nonatomic, assign) BOOL defaultIncludeNumber;

+ (instancetype)shared;
- (NSString *)generateNicknameWithStyle:(NSString *)style includeNumber:(BOOL)includeNumber;
- (void)toggleFavorite:(NSString *)nickname;
- (BOOL)isFavorite:(NSString *)nickname;
- (void)clearAllData;

@end

NS_ASSUME_NONNULL_END
