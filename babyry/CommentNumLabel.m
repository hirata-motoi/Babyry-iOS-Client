//
//  CommentNumLabel.m
//  babyry
//
//  Created by Kenji Suzuki on 2015/01/19.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import "CommentNumLabel.h"

@implementation CommentNumLabel

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
    CommentNumLabel *view = [[[NSBundle mainBundle] loadNibNamed:className owner:nil options:0] firstObject];
    return view;
}

- (void)setCommentNumber:(int)number
{
    if (number > 99) {
        number = 99;
    }
    self.num.text = [NSString stringWithFormat:@"%d", number];
}

@end
