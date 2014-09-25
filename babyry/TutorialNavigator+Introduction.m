//
//  TutorialNavigator+Introduction.m
//  babyry
//
//  Created by hirata.motoi on 2014/09/20.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "TutorialNavigator+Introduction.h"
#import "ICTutorialOverlay.h"
#import "PageContentViewController.h"
#import "TutorialIntroductionView.h"
#import "Tutorial.h"

@implementation TutorialNavigator_Introduction {
    ICTutorialOverlay *overlay;
    TutorialIntroductionView *view;
}

- (void)show
{
    overlay = [[ICTutorialOverlay alloc] init];
    overlay.hideWhenTapped = NO;
    overlay.animated = YES;
    [overlay show];
    
    view = [TutorialIntroductionView view];
    
    CGSize viewSize = self.targetViewController.view.frame.size;
    CGRect rect = view.frame;
    rect.origin.x = (viewSize.width - rect.size.width) / 2;
    rect.origin.y = 100;
    view.frame = rect;
    [view.forwardButton addTarget:self action:@selector(forwardNextTutorial) forControlEvents:UIControlEventTouchUpInside];
    
    [overlay addSubview:view];    
}

- (void)remove
{
    [overlay hide];
}

- (void)forwardNextTutorial
{       
    [self remove];
    [Tutorial forwardStageWithNextStage:@"chooseByUser"];
    PageContentViewController *vc = (PageContentViewController *)self.targetViewController;
    [vc viewWillAppear:YES];
}

@end
