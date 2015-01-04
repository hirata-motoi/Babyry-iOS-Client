//
//  CellImageFramePlaceHolderLarge.m
//  babyry
//
//  Created by Kenji Suzuki on 2015/01/03.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import "CellImageFramePlaceHolderLarge.h"

@implementation CellImageFramePlaceHolderLarge

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
    CellImageFramePlaceHolderLarge *view = [[[NSBundle mainBundle] loadNibNamed:className owner:nil options:0] firstObject];
    return view;
}

@end
