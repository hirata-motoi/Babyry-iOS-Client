//
//  TutorialNavigator+AddChild.m
//  babyry
//
//  Created by hirata.motoi on 2014/09/18.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "TutorialNavigator+AddChild.h"
#import "TutorialAddChildView.h"
#import "ICTutorialOverlay.h"
#import "ChildSwitchControlView.h"

@implementation TutorialNavigator_AddChild {
    TutorialAddChildView *view;
    ICTutorialOverlay *overlay;
}

- (void)show
{
    view = [TutorialAddChildView view];
    
    CGSize viewSize = self.targetViewController.view.frame.size;
    CGRect rect = view.frame;
    rect.origin.x = (viewSize.width - rect.size.width) / 2;
    rect.origin.y = 340;
    view.frame = rect;
    
    ChildSwitchControlView *childSwitchControlView = [ChildSwitchControlView sharedManager];
    [childSwitchControlView setupChildSwitchViews];
    [childSwitchControlView openChildSwitchViews];
    ChildSwitchView *childAddIcon = [childSwitchControlView getChildAddIcon];
    
    overlay = [[ICTutorialOverlay alloc] init];
    overlay.hideWhenTapped = NO;
    overlay.animated = YES;
    [overlay addHoleWithView:childAddIcon padding:8.0f offset:CGSizeZero form:ICTutorialOverlayHoleFormRoundedRectangle transparentEvent:YES];
    [overlay show];
    [overlay addSubview:view];
    
    UIButton *skipButton = [self createTutorialSkipButton];
    CGRect skipRect = skipButton.frame;
    skipRect.origin.x = 140;
    skipRect.origin.y = rect.origin.y + rect.size.height + 10;
    skipButton.frame = skipRect;
    [overlay addSubview:skipButton];
}

- (void)remove
{
    [view removeFromSuperview];
    [overlay hide];
}

@end
