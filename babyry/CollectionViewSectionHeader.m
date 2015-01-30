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
    CollectionViewSectionHeader *headerView = [[[NSBundle mainBundle] loadNibNamed:className owner:nil options:0] firstObject];
    
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc]initWithTarget:headerView action:@selector(toggleCells)];
    gesture.numberOfTapsRequired = 1;
    [headerView addGestureRecognizer:gesture];
    
    return headerView;
}

- (void)setParmetersWithYear:(NSInteger)year withMonth:(NSInteger)month
{
    _yearLabel.text = [NSString stringWithFormat:@"%ld", (long)year];
    _monthLabel.text = [NSString stringWithFormat:@"%ld月", (long)month];
    
    _yearLabel.textColor = [UIColor whiteColor];
    _yearLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14];
    
    _monthLabel.textColor = [UIColor whiteColor];
    _monthLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20];
                                                                                                                       
    self.backgroundColor = [ColorUtils getSectionHeaderColor];
}

- (void)toggleCells
{
    BOOL isExpanded = [_delegate toggleCells:_sectionIndex];
    [self adjustStyle:isExpanded];
}

- (void)adjustStyle:(BOOL)isExpanded
{
    // 閉じている時はborderを表示
    _borderBottom.hidden = isExpanded;
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
