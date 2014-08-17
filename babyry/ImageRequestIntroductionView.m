//
//  ImageRequestIntroductionView.m
//  babyry
//
//  Created by hirata.motoi on 2014/08/17.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ImageRequestIntroductionView.h"
#import "UIColor+Hex.h"
#import "ColorUtils.h"

@implementation ImageRequestIntroductionView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
}

+ (instancetype)view
{
    NSString *className = NSStringFromClass([self class]);
    ImageRequestIntroductionView *view = [[[NSBundle mainBundle] loadNibNamed:className owner:nil options:0] firstObject];
    view.backgroundColor = [UIColor_Hex colorWithHexString:@"000000" alpha:0.7];
    view.layer.cornerRadius = 5;
    view.backgroundView.layer.cornerRadius = 5;
    view.titleLabel.textColor = [ColorUtils getBabyryColor];
    
    UITapGestureRecognizer *closeGesture = [[UITapGestureRecognizer alloc]initWithTarget:view action:@selector(close)];
    closeGesture.numberOfTapsRequired = 1;
    view.closeButton.userInteractionEnabled = YES;
    [view.closeButton addGestureRecognizer:closeGesture];
    
    return view;
}

- (void)close
{
    [self removeFromSuperview];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
