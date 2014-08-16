//
//  BadgeNotify.m
//  babyry
//
//  Created by hirata.motoi on 2014/08/16.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "BadgeNotify.h"
#import "UIColor+Hex.h"

@implementation BadgeNotify

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
    BadgeNotify *view = [[[NSBundle mainBundle] loadNibNamed:className owner:nil options:0] firstObject];
    //view.backgroundColor = [UIColor_Hex colorWithHexString:@"ff7f7f" alpha:1.0];
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
