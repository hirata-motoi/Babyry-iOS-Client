//
//  TutorialNavigator+PartChange.m
//  babyry
//
//  Created by hirata.motoi on 2014/09/18.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "TutorialNavigator+PartChange.h"
#import "TutorialPartChangeView.h"
#import "TutorialUpperArrowView.h"
#import "ICTutorialOverlay.h"
#import "PageContentViewController.h"

@implementation TutorialNavigator_PartChange {
    TutorialPartChangeView *view;
    TutorialUpperArrowView *viewArrow;
    ICTutorialOverlay *overlay;
}

- (void)show
{
    overlay = [[ICTutorialOverlay alloc]init];
    overlay.hideWhenTapped = NO;
    overlay.animated = YES;
    [overlay addHoleWithRect:CGRectMake(270, 20, 44, 44) form:ICTutorialOverlayHoleFormRoundedRectangle transparentEvent:YES];
    [overlay show];
    
    view = [TutorialPartChangeView view];
    
    CGSize viewSize = self.targetViewController.view.frame.size;
    CGRect rect = view.frame;
    rect.origin.x = (viewSize.width - rect.size.width) / 2;
    rect.origin.y = 300;
    view.frame = rect;
    
    [overlay addSubview:view];
    
//    viewArrow = [TutorialUpperArrowView view];
//    CGRect rectArrow = viewArrow.frame;
//    rectArrow.origin.x = viewSize.width - rectArrow.size.width - 15;
//    rectArrow.origin.y = 64;
//    viewArrow.frame = rectArrow;
//    [self.targetViewController.view addSubview:viewArrow];
//    [NSTimer
//        scheduledTimerWithTimeInterval:0.5f
//        target:self
//        selector:@selector(blink:)
//        userInfo:nil
//        repeats:YES
//    ];
}

- (void)remove
{
    [view removeFromSuperview];
    [viewArrow removeFromSuperview];
    [overlay hide];
}

- (void)blink:(NSTimer *)timer
{
    viewArrow.hidden = !viewArrow.hidden;
}

@end
