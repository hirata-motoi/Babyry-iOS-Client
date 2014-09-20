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
    TutorialFamilyApplyIntroduceView *view;
    TutorialBestShotSelectedView *messageView;
    ICTutorialOverlay *overlay;
}

- (void)show
{
    view = [TutorialFamilyApplyIntroduceView view];
    CGRect rect = view.frame;
    rect.origin.x = 0;
    rect.origin.y = 64;
    view.frame = rect;
   
    // パートナー申請誘導viewの分collection viewを小さくする
    PageContentViewController *vc = (PageContentViewController *)self.targetViewController;
    CGRect collectionRect = vc.pageContentCollectionView.frame;
    collectionRect.size.height = collectionRect.size.height - rect.size.height;
    collectionRect.origin.y = collectionRect.origin.y + rect.size.height;
    vc.pageContentCollectionView.frame = collectionRect;
    
    [view.openFamilyApplyButton addTarget:vc action:@selector(openFamilyApply) forControlEvents:UIControlEventTouchUpInside];
    
    [vc.view addSubview:view];
    
    overlay = [[ICTutorialOverlay alloc] init];
    overlay.hideWhenTapped = NO;
    overlay.animated = YES;
    [overlay addHoleWithView:view.openFamilyApplyButton padding:4.0f offset:CGSizeZero form:ICTutorialOverlayHoleFormRoundedRectangle transparentEvent:YES];
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
    // パートナー申請誘導viewで小さくなっていた分collection viewを大きくする
    CGRect rect = view.frame;
    PageContentViewController *vc = (PageContentViewController *)self.targetViewController;
    CGRect collectionRect = vc.pageContentCollectionView.frame;
    
    collectionRect.size.height = collectionRect.size.height + rect.size.height;
    collectionRect.origin.y = collectionRect.origin.y - rect.size.height;
    vc.pageContentCollectionView.frame = collectionRect;
    
    [overlay hide];
}

@end
