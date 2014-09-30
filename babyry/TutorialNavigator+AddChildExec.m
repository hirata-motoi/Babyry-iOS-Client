//
//  TutorialNavigator+AddChildExec.m
//  babyry
//
//  Created by hirata.motoi on 2014/09/18.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "TutorialNavigator+AddChildExec.h"
#import "ICTutorialOverlay.h"
#import "IntroChildNameViewController.h"

@implementation TutorialNavigator_AddChildExec {
    ICTutorialOverlay *overlay;
}

- (void)show
{
    // IntroChildViewControllerを改修したら対応する
//    IntroChildNameViewController *vc = (IntroChildNameViewController *)self.targetViewController;
//    overlay = [[ICTutorialOverlay alloc]init];
//    overlay.hideWhenTapped = NO;
//    overlay.animated = YES;
//    [overlay addHoleWithView:vc.childNameField4 padding:3.0f offset:CGSizeZero form:ICTutorialOverlayHoleFormRoundedRectangle transparentEvent:YES];
//    [overlay show];
}

- (void)remove
{
    [overlay hide];
}

@end
