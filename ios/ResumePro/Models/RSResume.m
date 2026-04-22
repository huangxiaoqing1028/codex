#import "RSResume.h"

@implementation RSResume

+ (BOOL)supportsSecureCoding { return YES; }

+ (instancetype)emptyResume {
    RSResume *resume = [[RSResume alloc] init];
    resume.resumeId = [NSUUID UUID].UUIDString;
    resume.fullName = @"";
    resume.phone = @"";
    resume.email = @"";
    resume.jobTitle = @"";
    resume.summary = @"";
    resume.education = @"";
    resume.experience = @"";
    resume.skills = @"";
    resume.templateId = @"business_dark";
    resume.updatedAt = [NSDate date];
    return resume;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.resumeId forKey:@"resumeId"];
    [coder encodeObject:self.fullName forKey:@"fullName"];
    [coder encodeObject:self.phone forKey:@"phone"];
    [coder encodeObject:self.email forKey:@"email"];
    [coder encodeObject:self.jobTitle forKey:@"jobTitle"];
    [coder encodeObject:self.summary forKey:@"summary"];
    [coder encodeObject:self.education forKey:@"education"];
    [coder encodeObject:self.experience forKey:@"experience"];
    [coder encodeObject:self.skills forKey:@"skills"];
    [coder encodeObject:self.templateId forKey:@"templateId"];
    [coder encodeObject:self.updatedAt forKey:@"updatedAt"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _resumeId = [coder decodeObjectOfClass:[NSString class] forKey:@"resumeId"] ?: [NSUUID UUID].UUIDString;
        _fullName = [coder decodeObjectOfClass:[NSString class] forKey:@"fullName"] ?: @"";
        _phone = [coder decodeObjectOfClass:[NSString class] forKey:@"phone"] ?: @"";
        _email = [coder decodeObjectOfClass:[NSString class] forKey:@"email"] ?: @"";
        _jobTitle = [coder decodeObjectOfClass:[NSString class] forKey:@"jobTitle"] ?: @"";
        _summary = [coder decodeObjectOfClass:[NSString class] forKey:@"summary"] ?: @"";
        _education = [coder decodeObjectOfClass:[NSString class] forKey:@"education"] ?: @"";
        _experience = [coder decodeObjectOfClass:[NSString class] forKey:@"experience"] ?: @"";
        _skills = [coder decodeObjectOfClass:[NSString class] forKey:@"skills"] ?: @"";
        _templateId = [coder decodeObjectOfClass:[NSString class] forKey:@"templateId"] ?: @"business_dark";
        _updatedAt = [coder decodeObjectOfClass:[NSDate class] forKey:@"updatedAt"] ?: [NSDate date];
    }
    return self;
}

@end
