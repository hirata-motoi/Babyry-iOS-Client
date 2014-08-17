//
//  CellBackgroundViewToEncourageChooseLarge.m
//  babyry
//
//  Created by hirata.motoi on 2014/08/05.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "CellBackgroundViewToEncourageChooseLarge.h"
#import "ColorUtils.h"

@implementation CellBackgroundViewToEncourageChooseLarge

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
    CellBackgroundViewToEncourageChooseLarge *view = [[[NSBundle mainBundle] loadNibNamed:className owner:nil options:0] firstObject];
    view.backgroundColor = [ColorUtils getCellBackgroundDefaultColor];
    return view;
}

- (void)layoutSubviews
{
    CGFloat height = self.frame.size.height;
    CGFloat width = height;
    _iconView.frame = CGRectMake((self.frame.size.width - width)/2, (self.frame.size.height - height)/2, width, height);
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
