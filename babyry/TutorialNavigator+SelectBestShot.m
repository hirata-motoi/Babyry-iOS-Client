//
//  TutorialNavigator+SelectBestShot.m
//  babyry
//
//  Created by hirata.motoi on 2014/09/18.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "TutorialNavigator+SelectBestShot.h"
#import "TutorialSelectBestShotView.h"

@implementation TutorialNavigator_SelectBestShot {
    TutorialSelectBestShotView *view;
}

- (void)show
{
    view = [TutorialSelectBestShotView view];
    
    CGSize viewSize = self.targetViewController.view.frame.size;
    CGRect rect = view.frame;
    rect.origin.x = (viewSize.width - rect.size.width) / 2;
    rect.origin.y = 300;
    view.frame = rect;
    [self.targetViewController.view addSubview:view];
}

- (void)remove
{
    [view removeFromSuperview];
}

@end
