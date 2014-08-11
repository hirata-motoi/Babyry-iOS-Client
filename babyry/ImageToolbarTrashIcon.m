//
//  ImageToolbarTrashIcon.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/08/12.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ImageToolbarTrashIcon.h"

@implementation ImageToolbarTrashIcon

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

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
