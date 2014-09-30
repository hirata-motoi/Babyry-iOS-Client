//
//  TutorialReceivedApplyView.m
//  babyry
//
//  Created by hirata.motoi on 2014/09/26.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "TutorialReceivedApplyView.h"

@implementation TutorialReceivedApplyView

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
    TutorialReceivedApplyView *view = [[[NSBundle mainBundle] loadNibNamed:className owner:nil options:0] firstObject];
    view.openReceivedApplyButton.layer.borderWidth = 1.0f;
    view.openReceivedApplyButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    view.openReceivedApplyButton.layer.cornerRadius = 5.0f;
    
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
