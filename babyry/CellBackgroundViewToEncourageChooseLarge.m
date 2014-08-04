//
//  CellBackgroundViewToEncourageChooseLarge.m
//  babyry
//
//  Created by hirata.motoi on 2014/08/05.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "CellBackgroundViewToEncourageChooseLarge.h"

@implementation CellBackgroundViewToEncourageChooseLarge

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
    
    // 初期化
    _iconView.image = [UIImage imageNamed:@"correct"];
}

+ (instancetype)view
{
    NSString *className = NSStringFromClass([self class]);
    return [[[NSBundle mainBundle] loadNibNamed:className owner:nil options:0] firstObject];
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
