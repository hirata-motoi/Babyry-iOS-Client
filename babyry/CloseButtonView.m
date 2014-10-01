//
//  CloseButtonView.m
//  babyry
//
//  Created by hirata.motoi on 2014/10/01.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "CloseButtonView.h"
#import "UIColor+Hex.h"

@implementation CloseButtonView

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
    CloseButtonView *view = [[[NSBundle mainBundle] loadNibNamed:className owner:nil options:0] firstObject];
    view.layer.cornerRadius = view.frame.size.width/2;
    view.backgroundColor = [UIColor_Hex colorWithHexString:@"000000" alpha:0.7];
    
    return view;
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
