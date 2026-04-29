#import <Foundation/Foundation.h>

@interface ResumeModel : NSObject <NSSecureCoding>
@property (nonatomic, copy) NSString *resumeId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *phone;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *targetRole;
@property (nonatomic, copy) NSString *summary;
@property (nonatomic, strong) NSDate *updatedAt;
- (NSDictionary *)toDictionary;
+ (instancetype)fromDictionary:(NSDictionary *)dict;
@end
