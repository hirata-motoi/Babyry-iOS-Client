//
//  TutorialNavigator+UploadByUser.m
//  babyry
//
//  Created by hirata.motoi on 2014/09/18.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "TutorialNavigator+UploadByUser.h"
#import "ICTutorialOverlay.h"
#import "PageContentViewController.h"
#import "TutorialUploadByUserView.h"

@implementation TutorialNavigator_UploadByUser {
    ICTutorialOverlay *overlay;
}

- (void)show
{
    PageContentViewController *vc = (PageContentViewController *)self.targetViewController;
    overlay = [[ICTutorialOverlay alloc]init];
    overlay.hideWhenTapped = NO;
    overlay.animated = YES;
    
    UICollectionViewCell *cell = vc.cellOfToday;
    CGRect rect = cell.frame;
    [overlay addHoleWithRect:CGRectMake(10, 64 + 30 + 10, rect.size.width - 20, rect.size.height - 20) form:ICTutorialOverlayHoleFormRoundedRectangle transparentEvent:YES];
    [overlay show];
    
    TutorialUploadByUserView *view = [TutorialUploadByUserView view];
    
    NSMutableDictionary *childProperty = vc.childProperty;
    view.message.text = [NSString stringWithFormat:@"%@ちゃんの登録が完了しました。\n次に写真のアップロードを行いましょう", childProperty[@"name"]];
    [view.message sizeToFit];
    CGRect viewRect = view.frame;
    viewRect.origin.x = (rect.size.width - viewRect.size.width) / 2;
    viewRect.origin.y = 64 + 30 + 10 + rect.size.height;
    view.frame = viewRect;
    [overlay addSubview:view];
}

- (void)remove
{
    [overlay hide];
}

@end
