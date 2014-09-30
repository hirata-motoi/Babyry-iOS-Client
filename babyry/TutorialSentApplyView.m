//
//  TutorialSentApplyView.m
//  babyry
//
//  Created by hirata.motoi on 2014/09/26.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "TutorialSentApplyView.h"

@implementation TutorialSentApplyView

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
    TutorialSentApplyView *view = [[[NSBundle mainBundle] loadNibNamed:className owner:nil options:0] firstObject];
    view.openPartnerApplyListButton.layer.borderWidth = 1.0f;
    view.openPartnerApplyListButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    view.openPartnerApplyListButton.layer.cornerRadius = 5.0f;
    
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
