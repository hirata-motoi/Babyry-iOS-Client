//
//  AddMonthToCalendarView.m
//  babyry
//
//  Created by hirata.motoi on 2014/10/06.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "AddMonthToCalendarView.h"

@implementation AddMonthToCalendarView

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
    AddMonthToCalendarView *view = [[[NSBundle mainBundle] loadNibNamed:className owner:nil options:0] firstObject];
    return view;
}

- (void)layoutSubviews
{
    [_messageLabel sizeToFit];
    CGRect rect = _messageLabel.frame;
    rect.origin.x = (self.frame.size.width - _messageLabel.frame.size.width)/2;
    _messageLabel.frame = rect;
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
