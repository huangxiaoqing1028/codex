#import "NGStyleChipButton.h"

@implementation NGStyleChipButton

- (instancetype)initWithTitle:(NSString *)title {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self setTitle:title forState:UIControlStateNormal];
        self.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
        self.layer.cornerRadius = 18;
        self.contentEdgeInsets = UIEdgeInsetsMake(9, 14, 9, 14);
        [self updateSelectedState:NO];
    }
    return self;
}

- (void)updateSelectedState:(BOOL)selected {
    if (selected) {
        self.backgroundColor = [UIColor colorWithRed:0.39 green:0.34 blue:0.95 alpha:1.0];
        [self setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        self.layer.borderWidth = 0;
    } else {
        self.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.16];
        [self setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.92] forState:UIControlStateNormal];
        self.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.20].CGColor;
        self.layer.borderWidth = 1;
    }
}

@end
