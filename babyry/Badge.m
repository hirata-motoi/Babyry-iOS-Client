//
//  Badge.m
//  babyry
//
//  Created by hirata.motoi on 2014/08/12.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "Badge.h"

@implementation Badge

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

+ (UIView *)badgeViewWithType:(NSString *)type withCount:(NSInteger)count
{
    if ([type isEqualToString:@"commentPosted"]) {
        return [self badgeForComment:count];
    } else {
        return [self badgeForBestShot:count];
    }
}

+ (UIImageView *)badgeForComment:(NSInteger)count
{
    NSInteger badgeHeight = 15;
    UIImageView *commentBadge = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, badgeHeight, badgeHeight)];
    commentBadge.image = [UIImage imageNamed:@"CommentGray"];
    
    UILabel *commentCountLabel = [[UILabel alloc]initWithFrame:commentBadge.frame];
    NSInteger limitedCount = (count >= 99) ? 99 : count;
    commentCountLabel.text = [NSString stringWithFormat:@"%ld", limitedCount];
    commentCountLabel.font = [self commonFontForBadge];
    commentCountLabel.textAlignment = UITextAlignmentCenter;
    [commentBadge addSubview:commentCountLabel];
    return commentBadge;
}

+ (UIView *)badgeForBestShot:(NSInteger)count
{
    NSInteger badgeHeight = 15;
    UIView *badge = [[UIView alloc]initWithFrame:CGRectMake(0, 0, badgeHeight, badgeHeight)];
    badge.backgroundColor = [UIColor redColor]; // 暫定
    badge.layer.cornerRadius = badgeHeight / 2;
    UILabel *label = [[UILabel alloc]initWithFrame:badge.frame];
    NSInteger limitedCount = (count >= 99) ? 99 : count;
    label.text = [NSString stringWithFormat:@"%ld", limitedCount];
    label.font = [self commonFontForBadge];
    label.textAlignment = UITextAlignmentCenter;
    [badge addSubview:label];
    return badge;
}

+ (UIFont *)commonFontForBadge
{
    UIFont *font = [UIFont fontWithName:@"ArialRoundedMTBold" size:9];
    return font;
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
