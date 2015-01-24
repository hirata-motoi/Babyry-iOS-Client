//
//  ChildProfileNameCell.m
//  babyry
//
//  Created by hirata.motoi on 2015/01/23.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import "ChildProfileNameCell.h"

@implementation ChildProfileNameCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)closeEditField
{
    [_nameField resignFirstResponder];
}

@end
