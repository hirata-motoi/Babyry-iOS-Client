//
//  TutorialNavigator+TutorialFinished.m
//  babyry
//
//  Created by hirata.motoi on 2014/09/18.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "TutorialNavigator+TutorialFinished.h"
#import "TutorialFamilyApplyIntroduceView.h"
#import "TutorialBestShotSelectedView.h"
#import "PageContentViewController.h"
#import "ICTutorialOverlay.h"
#import "Tutorial.h"

@implementation TutorialNavigator_TutorialFinished {
    TutorialBestShotSelectedView *messageView;
    ICTutorialOverlay *overlay;
}

- (void)show
{
    PageContentViewController *vc = (PageContentViewController *)self.targetViewController;
    overlay = [[ICTutorialOverlay alloc] init];
    overlay.hideWhenTapped = NO;
    overlay.animated = YES;
    [overlay addHoleWithView:vc.familyApplyIntroduceView.openFamilyApplyButton padding:4.0f offset:CGSizeZero form:ICTutorialOverlayHoleFormRoundedRectangle transparentEvent:YES];
    [overlay show];
    
    messageView = [TutorialBestShotSelectedView view];
    CGRect messageRect = messageView.frame;
    messageRect.origin.x = (vc.view.frame.size.width - messageRect.size.width) / 2;
    messageRect.origin.y = 200;
    messageView.frame = messageRect;
    [overlay addSubview:messageView];
}

- (void)remove
{
    [overlay hide];
}

@end