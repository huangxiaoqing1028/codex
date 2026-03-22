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
    NSUInteger seed = (NSUInteger)arc4random_uniform((u_int32_t)pool.count);
    NSUInteger idx = (seed + (NSUInteger)normalized) % pool.count;
    NSDictionary *entry = pool[idx];

    ENGNameResult *result = [ENGNameResult new];
    result.name = entry[@"name"];
    result.meaning = entry[@"meaning"];
    result.tagline = [NSString stringWithFormat:@"%@ · 幸运数字 %ld · 词库 %lu", entry[@"vibe"], (long)luckyNumber, (unsigned long)pool.count];
    return result;
}

- (NSArray<NSDictionary *> *)poolForStyle:(ENGNameStyle)style {
    static NSArray<NSDictionary *> *unisex = nil;
    static NSArray<NSDictionary *> *male = nil;
    static NSArray<NSDictionary *> *female = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        unisex = [self generatedPoolWithFirstNames:[self unisexFirstNames] targetCount:1000 styleLabel:@"中性" meaningTokens:[self unisexMeanings] vibes:[self unisexVibes]];
        male = [self generatedPoolWithFirstNames:[self maleFirstNames] targetCount:1000 styleLabel:@"男生" meaningTokens:[self maleMeanings] vibes:[self maleVibes]];
        female = [self generatedPoolWithFirstNames:[self femaleFirstNames] targetCount:1000 styleLabel:@"女生" meaningTokens:[self femaleMeanings] vibes:[self femaleVibes]];
    });

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

- (NSArray<NSDictionary *> *)generatedPoolWithFirstNames:(NSArray<NSString *> *)firstNames
                                              targetCount:(NSUInteger)targetCount
                                               styleLabel:(NSString *)styleLabel
                                            meaningTokens:(NSArray<NSString *> *)meanings
                                                    vibes:(NSArray<NSString *> *)vibes {
    NSArray<NSString *> *lastNames = @[@"Smith", @"Johnson", @"Brown", @"Davis", @"Miller", @"Wilson", @"Moore", @"Taylor", @"Anderson", @"Thomas", @"Jackson", @"White", @"Harris", @"Martin", @"Clark", @"Lewis", @"Walker", @"Hall", @"Allen", @"Young", @"King", @"Wright", @"Scott", @"Green", @"Baker", @"Adams", @"Nelson", @"Carter", @"Mitchell", @"Perez", @"Roberts", @"Turner", @"Phillips", @"Campbell", @"Parker", @"Evans", @"Edwards", @"Collins", @"Stewart", @"Sanchez", @"Morris", @"Rogers", @"Reed", @"Cook", @"Morgan", @"Bell", @"Murphy", @"Bailey", @"Rivera", @"Cooper"];

    NSMutableArray<NSDictionary *> *pool = [NSMutableArray arrayWithCapacity:targetCount];
    NSMutableSet<NSString *> *used = [NSMutableSet setWithCapacity:targetCount];

    NSUInteger firstCount = firstNames.count;
    NSUInteger lastCount = lastNames.count;
    NSUInteger meaningCount = meanings.count;
    NSUInteger vibeCount = vibes.count;

    for (NSUInteger i = 0; i < targetCount; i++) {
        NSString *first = firstNames[(i * 7 + i / 5) % firstCount];
        NSString *last = lastNames[(i * 13 + i / 3) % lastCount];
        NSString *name = [NSString stringWithFormat:@"%@ %@", first, last];

        if ([used containsObject:name]) {
            NSString *suffix = [NSString stringWithFormat:@"%02lu", (unsigned long)((i % 97) + 1)];
            name = [name stringByAppendingFormat:@" %@", suffix];
        }
        [used addObject:name];

        NSString *meaning = [NSString stringWithFormat:@"%@、%@、%@", meanings[i % meaningCount], meanings[(i + 3) % meaningCount], meanings[(i + 8) % meaningCount]];
        NSString *vibe = [NSString stringWithFormat:@"%@%@", styleLabel, vibes[i % vibeCount]];

        [pool addObject:@{
            @"name": name,
            @"meaning": meaning,
            @"vibe": vibe
        }];
    }

    return pool;
}

- (NSArray<NSString *> *)unisexFirstNames {
    return @[@"Avery", @"Riley", @"Jordan", @"Peyton", @"Quinn", @"Taylor", @"Morgan", @"Skyler", @"Hayden", @"Rowan", @"Parker", @"Reese", @"Dakota", @"Kendall", @"Emerson", @"Finley", @"Charlie", @"Alex", @"Harley", @"Sage", @"Cameron", @"Blake", @"Drew", @"Elliot", @"Remy", @"Phoenix", @"Toby", @"Micah", @"Shawn", @"Ari", @"Jamie", @"Robin", @"Frankie", @"Casey", @"Lane", @"Milan", @"Arden", @"Indigo", @"Noel", @"Jules", @"Rory", @"Wren", @"Briar", @"Ellis", @"River", @"Oakley", @"Marley", @"Bellamy", @"Justice", @"Keegan", @"Logan", @"Spencer", @"Sydney", @"Cory", @"Tatum", @"Alden", @"Shiloh", @"Yael", @"Monroe", @"Greer", @"Campbell", @"Gale", @"Merritt", @"Rene", @"Sutton", @"Teagan", @"Winter", @"Zephyr", @"Adair", @"Bailey", @"Reagan", @"Terry", @"Kyrie", @"Marlow", @"Soren", @"Lennon", @"Nico", @"Kieran", @"Ainsley", @"Mika", @"Perry", @"Cleo", @"Emory", @"Jaden", @"Kai", @"Lou", @"Misha", @"Onyx", @"Rylan", @"Scout", @"Tristan", @"Val", @"Arlo", @"Denver", @"Hollis", @"Lior", @"Nile", @"Pax", @"Rio", @"Sawyer", @"Zen"];
}

- (NSArray<NSString *> *)maleFirstNames {
    return @[@"Liam", @"Noah", @"Oliver", @"Elijah", @"James", @"William", @"Benjamin", @"Lucas", @"Henry", @"Theodore", @"Jack", @"Levi", @"Alexander", @"Jackson", @"Mateo", @"Daniel", @"Michael", @"Mason", @"Sebastian", @"Ethan", @"Logan", @"Owen", @"Samuel", @"Jacob", @"Asher", @"Aiden", @"John", @"Joseph", @"Wyatt", @"David", @"Leo", @"Luke", @"Julian", @"Hudson", @"Grayson", @"Matthew", @"Ezra", @"Gabriel", @"Carter", @"Isaac", @"Jayden", @"Luca", @"Anthony", @"Dylan", @"Lincoln", @"Thomas", @"Maverick", @"Elias", @"Josiah", @"Charles", @"Caleb", @"Christopher", @"Ezekiel", @"Miles", @"Jaxon", @"Isaiah", @"Andrew", @"Joshua", @"Nathan", @"Nolan", @"Adrian", @"Cameron", @"Santiago", @"Eli", @"Aaron", @"Ryan", @"Angel", @"Cooper", @"Waylon", @"Easton", @"Kai", @"Christian", @"Landon", @"Colton", @"Roman", @"Axel", @"Brooks", @"Jonathan", @"Robert", @"Jameson", @"Ian", @"Everett", @"Greyson", @"Wesley", @"Jeremiah", @"Hunter", @"Leonardo", @"Jordan", @"Jose", @"Bennett", @"Silas", @"Nicholas", @"Parker", @"Beau", @"Weston", @"Austin", @"Connor", @"Carson", @"Dominic", @"Xavier", @"Jace"];
}

- (NSArray<NSString *> *)femaleFirstNames {
    return @[@"Olivia", @"Emma", @"Charlotte", @"Amelia", @"Sophia", @"Isabella", @"Ava", @"Mia", @"Evelyn", @"Luna", @"Harper", @"Camila", @"Sofia", @"Scarlett", @"Elizabeth", @"Eleanor", @"Emily", @"Chloe", @"Mila", @"Violet", @"Penelope", @"Gianna", @"Aria", @"Abigail", @"Ella", @"Avery", @"Hazel", @"Nora", @"Layla", @"Lily", @"Aurora", @"Nova", @"Ellie", @"Madison", @"Grace", @"Isla", @"Willow", @"Zoe", @"Riley", @"Stella", @"Eliana", @"Ivy", @"Victoria", @"Emilia", @"Zoey", @"Naomi", @"Hannah", @"Lucy", @"Elena", @"Lillian", @"Maya", @"Leah", @"Paisley", @"Addison", @"Natalie", @"Valentina", @"Everly", @"Delilah", @"Leilani", @"Madelyn", @"Kinsley", @"Ruby", @"Sophie", @"Alice", @"Genesis", @"Claire", @"Audrey", @"Sadie", @"Aaliyah", @"Autumn", @"Nevaeh", @"Bella", @"Brooklyn", @"Kennedy", @"Samantha", @"Hailey", @"Ariana", @"Allison", @"Gabriella", @"Serenity", @"Cora", @"Madeline", @"Eva", @"Adeline", @"Lydia", @"Jade", @"Piper", @"Brielle", @"Lyla", @"Peyton", @"Athena", @"Ayla", @"Emery", @"Julia", @"Rose", @"Morgan", @"Blakely", @"Arianna", @"Quinn", @"Melody"];
}

- (NSArray<NSString *> *)unisexMeanings {
    return @[@"自由", @"灵感", @"勇气", @"平衡", @"探索", @"创造", @"包容", @"独立", @"真诚", @"光芒", @"希望", @"松弛", @"专注", @"成长", @"冒险", @"温暖", @"坚定", @"活力", @"纯粹", @"治愈"];
}

- (NSArray<NSString *> *)maleMeanings {
    return @[@"担当", @"魄力", @"领导", @"坚韧", @"守护", @"沉稳", @"远见", @"自律", @"荣耀", @"勇猛", @"机智", @"果敢", @"执着", @"可靠", @"进取", @"胸怀", @"风度", @"热忱", @"信念", @"开拓"];
}

- (NSArray<NSString *> *)femaleMeanings {
    return @[@"优雅", @"智慧", @"温柔", @"自信", @"浪漫", @"灵动", @"明媚", @"独立", @"细腻", @"坚定", @"治愈", @"热情", @"从容", @"纯真", @"创造", @"柔韧", @"清澈", @"魅力", @"勇敢", @"希望"];
}

- (NSArray<NSString *> *)unisexVibes {
    return @[@"·清新现代", @"·都市简约", @"·创意先锋", @"·学院高级", @"·轻盈活力", @"·松弛高级"];
}

- (NSArray<NSString *> *)maleVibes {
    return @[@"·经典绅士", @"·高知沉稳", @"·运动潮流", @"·商务精英", @"·复古质感", @"·未来极简"];
}

- (NSArray<NSString *> *)femaleVibes {
    return @[@"·法式优雅", @"·知性温柔", @"·甜酷时尚", @"·轻奢都市", @"·梦幻浪漫", @"·极简高级"];
}

@end
