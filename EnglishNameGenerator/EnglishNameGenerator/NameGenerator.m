#import "NameGenerator.h"

@implementation ENGNameResult
@end

@implementation NameGenerator

- (ENGNameResult *)generateNameWithStyle:(ENGNameStyle)style luckyNumber:(NSInteger)luckyNumber {
    NSArray<NSDictionary *> *pool = [self poolForStyle:style];
    if (pool.count == 0) {
        return [ENGNameResult new];
    }

    NSInteger normalized = MAX(0, luckyNumber);
    NSUInteger seed = (NSUInteger)(arc4random_uniform((u_int32_t)pool.count));
    NSUInteger idx = (seed + (NSUInteger)normalized) % pool.count;
    NSDictionary *entry = pool[idx];

    ENGNameResult *result = [ENGNameResult new];
    result.name = entry[@"name"];
    result.meaning = entry[@"meaning"];
    result.tagline = [NSString stringWithFormat:@"%@ · 幸运数字 %ld", entry[@"vibe"], (long)luckyNumber];
    return result;
}

- (NSArray<NSDictionary *> *)poolForStyle:(ENGNameStyle)style {
    NSArray *unisex = @[
        @{@"name": @"Avery", @"meaning": @"智慧且独立", @"vibe": @"清新现代"},
        @{@"name": @"Morgan", @"meaning": @"勇敢并富有领导力", @"vibe": @"都市精英"},
        @{@"name": @"Riley", @"meaning": @"热情乐观", @"vibe": @"轻快阳光"},
        @{@"name": @"Jordan", @"meaning": @"平衡与包容", @"vibe": @"高级简约"},
        @{@"name": @"Quinn", @"meaning": @"聪明且有创意", @"vibe": @"艺术气质"}
    ];

    NSArray *male = @[
        @{@"name": @"Ethan", @"meaning": @"坚定可靠", @"vibe": @"经典绅士"},
        @{@"name": @"Lucas", @"meaning": @"光明与希望", @"vibe": @"温暖阳光"},
        @{@"name": @"Noah", @"meaning": @"平静与智慧", @"vibe": @"高知沉稳"},
        @{@"name": @"Henry", @"meaning": @"王者风范", @"vibe": @"复古贵气"},
        @{@"name": @"Owen", @"meaning": @"年轻勇敢", @"vibe": @"运动潮流"}
    ];

    NSArray *female = @[
        @{@"name": @"Olivia", @"meaning": @"优雅与和平", @"vibe": @"法式优雅"},
        @{@"name": @"Sophia", @"meaning": @"智慧与魅力", @"vibe": @"知性温柔"},
        @{@"name": @"Amelia", @"meaning": @"勤奋且独立", @"vibe": @"现代轻奢"},
        @{@"name": @"Luna", @"meaning": @"月光般神秘", @"vibe": @"梦幻浪漫"},
        @{@"name": @"Chloe", @"meaning": @"青春与活力", @"vibe": @"甜酷时尚"}
    ];

    switch (style) {
        case ENGNameStyleMale:
            return male;
        case ENGNameStyleFemale:
            return female;
        case ENGNameStyleUnisex:
        default:
            return unisex;
    }
}

@end
