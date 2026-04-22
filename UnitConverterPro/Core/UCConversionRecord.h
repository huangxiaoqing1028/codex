#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UCConversionRecord : NSObject <NSSecureCoding>

@property (nonatomic, copy, readonly) NSString *categoryName;
@property (nonatomic, copy, readonly) NSString *inputText;
@property (nonatomic, copy, readonly) NSString *outputText;
@property (nonatomic, strong, readonly) NSDate *timestamp;

- (instancetype)initWithCategoryName:(NSString *)categoryName
                           inputText:(NSString *)inputText
                          outputText:(NSString *)outputText
                           timestamp:(NSDate *)timestamp;

@end

NS_ASSUME_NONNULL_END
