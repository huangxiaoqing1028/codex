#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RSResume : NSObject <NSSecureCoding>
@property (nonatomic, copy) NSString *resumeId;
@property (nonatomic, copy) NSString *fullName;
@property (nonatomic, copy) NSString *phone;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *jobTitle;
@property (nonatomic, copy) NSString *summary;
@property (nonatomic, copy) NSString *education;
@property (nonatomic, copy) NSString *experience;
@property (nonatomic, copy) NSString *skills;
@property (nonatomic, copy) NSString *templateId;
@property (nonatomic, strong) NSDate *updatedAt;
+ (instancetype)emptyResume;
@end

NS_ASSUME_NONNULL_END
