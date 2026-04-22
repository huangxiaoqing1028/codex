#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RSTemplate : NSObject
@property (nonatomic, copy) NSString *templateId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) BOOL premium;
@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, strong) UIColor *titleColor;
@property (nonatomic, strong) UIColor *bodyColor;
+ (instancetype)templateWithId:(NSString *)templateId
                          name:(NSString *)name
                       premium:(BOOL)premium
               backgroundColor:(UIColor *)backgroundColor
                    titleColor:(UIColor *)titleColor
                     bodyColor:(UIColor *)bodyColor;
@end

NS_ASSUME_NONNULL_END
