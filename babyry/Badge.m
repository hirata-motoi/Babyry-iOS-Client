//
//  Badge.m
//  babyry
//
//  Created by hirata.motoi on 2014/08/12.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "Badge.h"
#import "BadgeNotify.h"

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
    NSInteger badgeHeight = 22;
    NSInteger badgeWidth  = 26;
    UIImageView *commentBadge = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, badgeWidth, badgeHeight)];
    commentBadge.image = [UIImage imageNamed:@"CommentGreen"];
    
    UILabel *commentCountLabel = [[UILabel alloc]initWithFrame:commentBadge.frame];
    NSInteger limitedCount = (count >= 99) ? 99 : count;
    commentCountLabel.text = [NSString stringWithFormat:@"%ld", limitedCount];
    commentCountLabel.font = [self commonFontForBadge];
    commentCountLabel.textAlignment = UITextAlignmentCenter;
    commentCountLabel.textColor = [UIColor whiteColor];
    [commentBadge addSubview:commentCountLabel];
    return commentBadge;
}

+ (UIView *)badgeForBestShot:(NSInteger)count
{
    BadgeNotify *badge = [BadgeNotify view];
    badge.layer.cornerRadius = badge.frame.size.height/2;
    return badge;
}

+ (UIFont *)commonFontForBadge
{
    UIFont *font = [UIFont fontWithName:@"ArialRoundedMTBold" size:13];
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
