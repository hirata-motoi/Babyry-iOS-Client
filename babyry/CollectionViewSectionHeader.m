//
//  CollectionViewSectionHeader.m
//  babyry
//
//  Created by hirata.motoi on 2014/08/13.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "CollectionViewSectionHeader.h"
#import "ColorUtils.h"

@implementation CollectionViewSectionHeader

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

- (void)setParmetersWithYear:(NSInteger)year withMonth:(NSInteger)month withName:(NSString *)name
{
    _yearLabel.text = [NSString stringWithFormat:@"%ld", (long)year];
    _monthLabel.text = [NSString stringWithFormat:@"%ld月", (long)month];
    _nameLabel.text = [NSString stringWithFormat:@"%@ちゃん", name];
    
    _yearLabel.textColor = [UIColor whiteColor];
    _yearLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14];
    
    _monthLabel.textColor = [UIColor whiteColor];
    _monthLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20];
                                                            
    _nameLabel.textColor = [UIColor whiteColor];
    _nameLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:17];
                                                           
    self.backgroundColor = [ColorUtils getSectionHeaderColor];
    
    NSLog(@"color: %@", [ColorUtils getSectionHeaderColor]);
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
