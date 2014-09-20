//
//  TutorialBestShotSelectedView.m
//  babyry
//
//  Created by hirata.motoi on 2014/09/20.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "TutorialBestShotSelectedView.h"
#import "UIColor+Hex.h"

@implementation TutorialBestShotSelectedView

- (void)awakeFromNib
{
    [super awakeFromNib];
}

+ (instancetype)view
{
    NSString *className = NSStringFromClass([self class]);
    TutorialBestShotSelectedView *view = [[[NSBundle mainBundle] loadNibNamed:className owner:nil options:0] firstObject];
    view.backgroundColor = [UIColor_Hex colorWithHexString:@"000000" alpha:0.0f];
    view.layer.cornerRadius = 5;
    
    return view;
}

@end
