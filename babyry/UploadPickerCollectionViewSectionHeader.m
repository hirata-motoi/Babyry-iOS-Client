//
//  UploadPickerCollectionViewSectionHeader.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/11/05.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "UploadPickerCollectionViewSectionHeader.h"

@implementation UploadPickerCollectionViewSectionHeader

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
    return [[[NSBundle mainBundle] loadNibNamed:className owner:nil options:0] firstObject];
}

- (void)setDate:(NSString *)dateText
{
    _dateLabel.text = dateText;
    _dateLabel.textColor = [UIColor blackColor];
    _dateLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14];
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
