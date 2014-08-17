//
//  FamilyApplyListCell.m
//  babyry
//
//  Created by hirata.motoi on 2014/08/18.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "FamilyApplyListCell.h"

@implementation FamilyApplyListCell
@synthesize delegate;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
    
    // 承認ボタン
    UITapGestureRecognizer *admitGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(admit)];
    admitGesture.numberOfTapsRequired = 1;
    [_admitButton addGestureRecognizer:admitGesture];
}

- (void)admit
{
    [delegate admit:_index];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
