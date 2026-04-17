#import <Foundation/Foundation.h>
@class RSTemplate;

NS_ASSUME_NONNULL_BEGIN

@interface RSTemplateService : NSObject
+ (instancetype)shared;
- (NSArray<RSTemplate *> *)allTemplates;
- (RSTemplate *)templateById:(NSString *)templateId;
@end

NS_ASSUME_NONNULL_END
