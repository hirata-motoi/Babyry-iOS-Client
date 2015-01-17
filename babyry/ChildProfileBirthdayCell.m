//
//  ChildProfileBirthdayCell.m
//  babyry
//
//  Created by hirata.motoi on 2015/01/11.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import "ChildProfileBirthdayCell.h"

@implementation ChildProfileBirthdayCell

- (void)awakeFromNib {
    // Initialization code
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(edit)];
    tapGesture.numberOfTapsRequired = 1;
    [_birthdayLabel addGestureRecognizer:tapGesture];
    _birthdayLabel.userInteractionEnabled = YES;
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)edit
{
    // delegateのメソッドを叩く
    // datepickerviewを下からにゅっと表示
    [_delegate openDatePickerView:_childObjectId];
}

@end
