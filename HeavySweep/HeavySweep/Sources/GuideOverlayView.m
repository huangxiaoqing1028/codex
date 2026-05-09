#import "GuideOverlayView.h"

@interface GuideOverlayView ()
@property (nonatomic, copy) dispatch_block_t dismissBlock;
@end

@implementation GuideOverlayView
- (void)showInView:(UIView *)view text:(NSString *)text onDismiss:(dispatch_block_t)onDismiss {
    self.dismissBlock = onDismiss;
    self.frame=view.bounds;
    self.backgroundColor=[[UIColor blackColor] colorWithAlphaComponent:0.72];

    UILabel *l=[[UILabel alloc]initWithFrame:CGRectMake(24, 180, view.bounds.size.width-48, 150)];
    l.text=text; l.textColor=UIColor.whiteColor; l.numberOfLines=0;
    [self addSubview:l];

    UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];
    b.frame=CGRectMake(24, 360, view.bounds.size.width-48, 50);
    [b setTitle:@"我知道了" forState:UIControlStateNormal];
    [b addTarget:self action:@selector(onDismissTap) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:b];
    [view addSubview:self];
}

- (void)onDismissTap {
    [self removeFromSuperview];
    if (self.dismissBlock) { self.dismissBlock(); }
}
@end
