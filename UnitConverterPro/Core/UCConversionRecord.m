#import "UCConversionRecord.h"

@implementation UCConversionRecord

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCategoryName:(NSString *)categoryName
                           inputText:(NSString *)inputText
                          outputText:(NSString *)outputText
                           timestamp:(NSDate *)timestamp {
    self = [super init];
    if (self) {
        _categoryName = [categoryName copy];
        _inputText = [inputText copy];
        _outputText = [outputText copy];
        _timestamp = timestamp;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    NSString *categoryName = [coder decodeObjectOfClass:[NSString class] forKey:@"categoryName"];
    NSString *inputText = [coder decodeObjectOfClass:[NSString class] forKey:@"inputText"];
    NSString *outputText = [coder decodeObjectOfClass:[NSString class] forKey:@"outputText"];
    NSDate *timestamp = [coder decodeObjectOfClass:[NSDate class] forKey:@"timestamp"];
    return [self initWithCategoryName:categoryName inputText:inputText outputText:outputText timestamp:timestamp ?: [NSDate date]];
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.categoryName forKey:@"categoryName"];
    [coder encodeObject:self.inputText forKey:@"inputText"];
    [coder encodeObject:self.outputText forKey:@"outputText"];
    [coder encodeObject:self.timestamp forKey:@"timestamp"];
}

@end
