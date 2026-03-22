#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, ENGNameStyle) {
    ENGNameStyleUnisex,
    ENGNameStyleMale,
    ENGNameStyleFemale
};

@interface ENGNameResult : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *meaning;
@property (nonatomic, copy) NSString *tagline;
@end

@interface NameGenerator : NSObject
- (ENGNameResult *)generateNameWithStyle:(ENGNameStyle)style luckyNumber:(NSInteger)luckyNumber;
@end
