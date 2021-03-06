//
//  TutorialImageUploadFinishedView.m
//  babyry
//
//  Created by hirata.motoi on 2014/09/24.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "TutorialImageUploadFinishedView.h"
#import "ColorUtils.h"

@implementation TutorialImageUploadFinishedView

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
    TutorialImageUploadFinishedView *view = [[[NSBundle mainBundle] loadNibNamed:className owner:nil options:0] firstObject];
    view.backgroundColor = [UIColor clearColor];
    view.forwardButton.layer.cornerRadius = 2.0f;
    view.forwardButton.backgroundColor = [ColorUtils getBabyryColor];
         
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
