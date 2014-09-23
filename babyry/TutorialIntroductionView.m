//
//  TutorialIntroductionView.m
//  babyry
//
//  Created by hirata.motoi on 2014/09/20.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "TutorialIntroductionView.h"
#import "UIColor+Hex.h"

@implementation TutorialIntroductionView

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
    TutorialIntroductionView *view = [[[NSBundle mainBundle] loadNibNamed:className owner:nil options:0] firstObject];
    view.backgroundColor = [UIColor_Hex colorWithHexString:@"000000" alpha:0.0f];
    
    return view;
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
