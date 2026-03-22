#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ResumeData : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *targetRole;
@property (nonatomic, copy) NSString *phone;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *city;
@property (nonatomic, copy) NSString *portfolio;
@property (nonatomic, copy) NSString *summary;
@property (nonatomic, strong) NSArray<NSString *> *education;
@property (nonatomic, strong) NSArray<NSString *> *experiences;
@property (nonatomic, strong) NSArray<NSString *> *skills;
@property (nonatomic, strong) NSArray<NSString *> *projects;
@end

NS_ASSUME_NONNULL_END
