//
//  TutorialFamilyApplyIntroduceView.m
//  babyry
//
//  Created by hirata.motoi on 2014/09/18.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "TutorialFamilyApplyIntroduceView.h"

@implementation TutorialFamilyApplyIntroduceView

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
    TutorialFamilyApplyIntroduceView *view = [[[NSBundle mainBundle] loadNibNamed:className owner:nil options:0] firstObject];
    view.openFamilyApplyButton.layer.borderWidth = 1.0f;
    view.openFamilyApplyButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    view.openFamilyApplyButton.layer.cornerRadius = 5.0f;
    
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
