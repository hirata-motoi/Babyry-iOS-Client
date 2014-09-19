//
//  TutorialNavigator+ShowMultiUpload.m
//  babyry
//
//  Created by hirata.motoi on 2014/09/17.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "TutorialNavigator+ShowMultiUpload.h"
#import "TutorialShowMultiUploadView.h"
#import "ICTutorialOverlay.h"
#import "PageContentViewController.h"

@implementation TutorialNavigator_ShowMultiUpload {
    TutorialShowMultiUploadView *view;
    ICTutorialOverlay *overlay;
}

- (void)show
{
    PageContentViewController *vc = (PageContentViewController *)self.targetViewController;
    overlay = [[ICTutorialOverlay alloc] init];
    overlay.hideWhenTapped = NO;
    overlay.animated = YES;
    UICollectionViewCell *cell = vc.cellOfToday;
    CGRect r = cell.frame;
    [overlay addHoleWithRect:CGRectMake(10, 64 + 40, r.size.width - 20, r.size.height - 20) form:ICTutorialOverlayHoleFormRoundedRectangle transparentEvent:YES];
    [overlay show];
    [vc.pageContentCollectionView setScrollEnabled:NO];
    
    view = [TutorialShowMultiUploadView view];
   
    CGSize viewSize = self.targetViewController.view.frame.size;
    CGRect rect = view.frame;
    rect.origin.x = (viewSize.width - rect.size.width) / 2;
    rect.origin.y = 64 + 30 + r.size.height - 10;
    view.frame = rect;
    //[self.targetViewController.view addSubview:view];
    [overlay addSubview:view];
}

- (void)remove
{
    [view removeFromSuperview];
    [overlay hide];
}

- (void)overrideButton
{
    NSLog(@"overrideButton %@", self.targetViewController.parentViewController.parentViewController.navigationItem.rightBarButtonItem);
    UIButton *openGlobalSettingButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    [openGlobalSettingButton setBackgroundImage:[UIImage imageNamed:@"CogWheel"] forState:UIControlStateNormal];
    self.targetViewController.parentViewController.parentViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:openGlobalSettingButton];
    //self.targetViewController.parentViewController.navigationBar.tintColor = [UIColor whiteColor];
}

@end
