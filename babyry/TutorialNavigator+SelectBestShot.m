//
//  TutorialNavigator+SelectBestShot.m
//  babyry
//
//  Created by hirata.motoi on 2014/09/18.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "TutorialNavigator+SelectBestShot.h"
#import "TutorialSelectBestShotView.h"
#import "ICTutorialOverlay.h"
#import "MultiUploadViewController.h"

@implementation TutorialNavigator_SelectBestShot {
    TutorialSelectBestShotView *view;
    ICTutorialOverlay *overlay;
}

- (void)show
{
    
    view = [TutorialSelectBestShotView view];
    
    CGSize viewSize = self.targetViewController.view.frame.size;
    CGRect rect = view.frame;
    rect.origin.x = (viewSize.width - rect.size.width) / 2;
    rect.origin.y = 300;
    view.frame = rect;
    //[self.targetViewController.view addSubview:view];
   
    MultiUploadViewController *vc = (MultiUploadViewController *)self.targetViewController;
    overlay = [[ICTutorialOverlay alloc] init];
    overlay.hideWhenTapped = NO;
    overlay.animated = YES;
    [overlay addHoleWithView:vc.firstCellUnselectedBestShotView padding:3.0f offset:CGSizeZero form:ICTutorialOverlayHoleFormRoundedRectangle transparentEvent:YES];
    MultiUploadViewController+Logic+Tutorial.m[overlay show];
    [overlay addSubview:view];
}

- (void)remove
{
    [view removeFromSuperview];
    [overlay hide];
}

@end
