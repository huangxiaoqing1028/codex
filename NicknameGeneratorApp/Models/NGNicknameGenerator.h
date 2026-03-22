#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NGNicknameGenerator : NSObject

@property (nonatomic, readonly) NSArray<NSString *> *recentNicknames;
@property (nonatomic, readonly) NSArray<NSString *> *favoriteNicknames;

- (NSString *)generateNicknameWithStyle:(NSString *)style includeNumber:(BOOL)includeNumber;
- (void)toggleFavorite:(NSString *)nickname;
- (BOOL)isFavorite:(NSString *)nickname;

@end

NS_ASSUME_NONNULL_END
