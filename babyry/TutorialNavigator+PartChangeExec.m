//
//  TutorialNavigator+PartChangeExec.m
//  babyry
//
//  Created by hirata.motoi on 2014/09/18.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "TutorialNavigator+PartChangeExec.h"
#import "TutorialPartChangeExecView.h"
#import "ICTutorialOverlay.h"
#import "GlobalSettingViewController.h"

@implementation TutorialNavigator_PartChangeExec {
    TutorialPartChangeExecView *view;
    ICTutorialOverlay *overlay;
}

- (void)show
{
    GlobalSettingViewController *vc = (GlobalSettingViewController *)self.targetViewController;
    overlay = [[ICTutorialOverlay alloc] init];
    overlay.hideWhenTapped = NO;
    overlay.animated = YES;
    [overlay addHoleWithView:vc.partSwitchCell padding:3.0f offset:CGSizeZero form:ICTutorialOverlayHoleFormRoundedRectangle transparentEvent:YES];
    [overlay show];
    
    view = [TutorialPartChangeExecView view];
    CGSize viewSize = self.targetViewController.view.frame.size;
    CGRect rect = view.frame;
    rect.origin.x = (viewSize.width - rect.size.width) / 2;
    rect.origin.y = 200;
    view.frame = rect;
    
    [overlay addSubview:view];
}

- (void)remove
{
    [view removeFromSuperview];
    [overlay hide];
}

@end
