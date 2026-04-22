#import "UCCardView.h"

@implementation UCCardView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.whiteColor;
        self.layer.cornerRadius = 20;
        self.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.08].CGColor;
        self.layer.shadowOpacity = 1;
        self.layer.shadowRadius = 18;
        self.layer.shadowOffset = CGSizeMake(0, 10);
    }
    return self;
}

@end
