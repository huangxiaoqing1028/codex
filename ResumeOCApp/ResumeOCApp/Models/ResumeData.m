#import "ResumeData.h"

@implementation ResumeData

- (instancetype)init {
    self = [super init];
    if (self) {
        _name = @"";
        _targetRole = @"";
        _phone = @"";
        _email = @"";
        _city = @"";
        _portfolio = @"";
        _summary = @"";
        _education = @[];
        _experiences = @[];
        _skills = @[];
        _projects = @[];
    }
    return self;
}

@end
