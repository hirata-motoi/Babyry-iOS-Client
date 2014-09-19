//
//  ChildListCell.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/09/18.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ChildListCell.h"

@implementation ChildListCell

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
    ChildListCell *view = [[[NSBundle mainBundle] loadNibNamed:className owner:nil options:0] firstObject];
    return view;
}

@end
