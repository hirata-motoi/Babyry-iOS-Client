//
//  DatePickerView.m
//  babyry
//
//  Created by hirata.motoi on 2015/01/11.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import "DatePickerView.h"

@implementation DatePickerView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)awakeFromNib
{
    [super awakeFromNib];
}

+ (instancetype)view
{
    NSString *className = NSStringFromClass([self class]);
    DatePickerView *view = [[[NSBundle mainBundle] loadNibNamed:className owner:nil options:0] firstObject];
   
    UITapGestureRecognizer *saveGesture = [[UITapGestureRecognizer alloc]initWithTarget:view action:@selector(saveBirthday)];
    saveGesture.numberOfTapsRequired = 1;
    [view.saveButton addGestureRecognizer:saveGesture];
    
    return view;
}

- (void)saveBirthday
{
    NSLog(@"saveBirthday tapped");
    [_delegate saveBirthday:_childObjectId];
}


@end
