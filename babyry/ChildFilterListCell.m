//
//  ChildFilterListCell.m
//  babyry
//
//  Created by hirata.motoi on 2014/11/05.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ChildFilterListCell.h"

@implementation ChildFilterListCell
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
    [_selectSwitch addTarget:self action:@selector(switched) forControlEvents:UIControlEventValueChanged];

}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)switched
{
    BOOL succeeded = [delegate switchSelected:_selectSwitch.on withIndexPath:_indexPath];
    if (!succeeded) {
        _selectSwitch.on = !_selectSwitch.on;
    }
}

@end
