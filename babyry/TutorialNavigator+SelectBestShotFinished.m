//
//  TutorialNavigator+SelectBestShotFinished.m
//  babyry
//
//  Created by hirata.motoi on 2014/09/24.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "TutorialNavigator+SelectBestShotFinished.h"
#import "ICTutorialOverlay.h"
#import "MultiUploadViewController.h"
#import "TutorialSelectBestShotFinishedView.h"

@implementation TutorialNavigator_SelectBestShotFinished {
    ICTutorialOverlay *overlay;
    TutorialSelectBestShotFinishedView *view;
}

- (void)show
{
    MultiUploadViewController *vc = (MultiUploadViewController *)self.targetViewController;
    view = [TutorialSelectBestShotFinishedView view];
    
    CGSize viewSize = self.targetViewController.view.frame.size;
    CGRect rect = view.frame;
    rect.origin.x = (viewSize.width - rect.size.width) / 2;
    rect.origin.y = 300;
    view.frame = rect;
    [view.forwardButton addTarget:vc action:@selector(forwardNextTutorial) forControlEvents:UIControlEventTouchUpInside];
   
    overlay = [[ICTutorialOverlay alloc] init];
    overlay.hideWhenTapped = NO;
    overlay.animated = YES;
    [overlay show];
    [overlay addSubview:view];
    
    UIButton *skipButton = [self createTutorialSkipButton];
    CGRect skipRect = skipButton.frame;
    skipRect.origin.x = 160;
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
