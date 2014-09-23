//
//  TutorialNavigator+ImageUploadFinished.m
//  babyry
//
//  Created by hirata.motoi on 2014/09/24.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "TutorialNavigator+ImageUploadFinished.h"
#import "ICTutorialOverlay.h"
#import "PageContentViewController.h"
#import "TutorialImageUploadFinishedView.h"

@implementation TutorialNavigator_ImageUploadFinished {
    ICTutorialOverlay *overlay;
    TutorialImageUploadFinishedView *view;
}

- (void)show
{
    PageContentViewController *vc = (PageContentViewController *)self.targetViewController;
    view = [TutorialImageUploadFinishedView view];
    
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
