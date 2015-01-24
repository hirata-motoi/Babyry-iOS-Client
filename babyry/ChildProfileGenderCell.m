//
//  ChildProfileGenderCell.m
//  babyry
//
//  Created by hirata.motoi on 2015/01/10.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import "ChildProfileGenderCell.h"
#import "GenderSegmentControl.h"
#import "ColorUtils.h"

@implementation ChildProfileGenderCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setupSegmentControl:(NSMutableDictionary *)params
{
    [_segmentControl removeFromSuperview];
    _segmentControl = nil;
    _segmentControl = [[GenderSegmentControl alloc]initWithParams:params];
    
    [_segmentControl addTarget:self action:@selector(switchGender:) forControlEvents:UIControlEventValueChanged];
    CGRect rect =  _segmentControl.frame;
    rect.origin.x = self.frame.size.width - rect.size.width - 20;
    rect.origin.y = (self.frame.size.height - rect.size.height ) / 2;
    _segmentControl.frame = rect;
    _segmentControl.tintColor = [ColorUtils getGlobalMenuPartSwitchColor];

    [self.contentView addSubview:_segmentControl];
}

- (void)switchGender:(id)sender
{
    [_delegate switchGender:sender];
}

@end
