//
//  TutorialNavigator.m
//  babyry
//
//  Created by hirata.motoi on 2014/09/17.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "TutorialNavigator.h"
#import "Tutorial.h"
#import "TutorialStage.h"
#import "TutorialNavigator+Introduction.h"
#import "TutorialNavigator+ShowMultiUpload.h"
#import "TutorialNavigator+SelectBestShot.h"
#import "TutorialNavigator+SelectBestShotFinished.h"
#import "TutorialNavigator+PartChange.h"
#import "TutorialNavigator+PartChangeExec.h"
#import "TutorialNavigator+AddChild.h"
#import "TutorialNavigator+AddChildExec.h"
#import "TutorialNavigator+UploadByUser.h"
#import "TutorialNavigator+ImageUploadFinished.h"
#import "TutorialNavigator+TutorialFinished.h"
#import "Config.h"
#import "PageContentViewController.h"
#import "MultiUploadViewController.h"
#import "GlobalSettingViewController.h"
#import "IntroChildNameViewController.h"
#import "ICTutorialOverlay.h"
#import "FamilyRole.h"
#import "ViewController.h"
#import "ChildProperties.h"

@implementation TutorialNavigator {
    TutorialNavigator *navigator_;
}

- (BOOL)showNavigationView
{
    TutorialStage *stage = [TutorialStage MR_findFirst];
    if (!stage) {
        return NO;
    }
   
    if ([stage.currentStage isEqualToString:@"introduction"]) {
        if ([_targetViewController isKindOfClass:[PageContentViewController class]]) {
            TutorialNavigator_Introduction *navigator = [[TutorialNavigator_Introduction alloc]init];
            navigator.targetViewController = _targetViewController;
            [navigator show];
            navigator_ = navigator;
            return YES;
        }
    } else if ([stage.currentStage isEqualToString:@"chooseByUser"]) {
        if ([_targetViewController isKindOfClass:[PageContentViewController class]]) {
            TutorialNavigator_ShowMultiUpload *navigator = [[TutorialNavigator_ShowMultiUpload alloc]init];
            navigator.targetViewController = _targetViewController;
            [navigator show];
            navigator_ = navigator;
            return YES;
        } else if ([_targetViewController isKindOfClass:[MultiUploadViewController class]]) {
            TutorialNavigator_SelectBestShot *navigator = [[TutorialNavigator_SelectBestShot alloc]init];
            navigator.targetViewController = _targetViewController;
            [navigator show];
            navigator_ = navigator;
            return YES;
        }
    } else if ([stage.currentStage isEqualToString:@"partChange"]) {
        if ([_targetViewController isKindOfClass:[MultiUploadViewController class]]) {
            TutorialNavigator_SelectBestShotFinished *navigator = [[TutorialNavigator_SelectBestShotFinished alloc]init];
            navigator.targetViewController = _targetViewController;
            [navigator show];
            navigator_ = navigator;
            return YES;
        } else if ([_targetViewController isKindOfClass:[PageContentViewController class]]) {
            TutorialNavigator_PartChange *navigator = [[TutorialNavigator_PartChange alloc]init];
            navigator.targetViewController = _targetViewController;
            [navigator show];
            navigator_ = navigator;
            return YES;
        } else if ([_targetViewController isKindOfClass:[GlobalSettingViewController class]]) {
            TutorialNavigator_PartChangeExec *navigator = [[TutorialNavigator_PartChangeExec alloc]init];
            navigator.targetViewController = _targetViewController;
            [navigator show];
            navigator_ = navigator;
            return YES;
        }
    } else if ([stage.currentStage isEqualToString:@"addChild"]) {
        if ([_targetViewController isKindOfClass:[ViewController class]]) {
            TutorialNavigator_AddChild *navigator = [[TutorialNavigator_AddChild alloc]init];
            navigator.targetViewController = _targetViewController;
            [navigator show];
            navigator_ = navigator;
            return YES;
        } else if ([_targetViewController isKindOfClass:[IntroChildNameViewController class]]) {
            TutorialNavigator_AddChildExec *navigator = [[TutorialNavigator_AddChildExec alloc]init];
            navigator.targetViewController = _targetViewController;
            [navigator show];
            navigator_ = navigator;
            return YES;
        }
    } else if ([stage.currentStage isEqualToString:@"uploadByUser"]) {
        if ([_targetViewController isKindOfClass:[PageContentViewController class]]) {
            TutorialNavigator_UploadByUser *navigator = [[TutorialNavigator_UploadByUser alloc]init];
            navigator.targetViewController = _targetViewController;
            [navigator show];
            navigator_ = navigator;
            return YES;
        }
    } else if ([stage.currentStage isEqualToString:@"uploadByUserFinished"]) {
        if ([_targetViewController isKindOfClass:[PageContentViewController class]]) {
            TutorialNavigator_ImageUploadFinished *navigator = [[TutorialNavigator_ImageUploadFinished alloc]init];
            navigator.targetViewController = _targetViewController;
            [navigator show];
            navigator_ = navigator;
            return YES;
        }
    } else if ([stage.currentStage isEqualToString:@"familyApply"]) {
        if ([_targetViewController isKindOfClass:[ViewController class]]) {
            TutorialNavigator_TutorialFinished *navigator = [[TutorialNavigator_TutorialFinished alloc]init];
            navigator.targetViewController = _targetViewController;
            [navigator show];
            navigator_ = navigator;
            return YES;
        }
    }
    return NO;
}

- (void)removeNavigationView
{
    [navigator_ remove];
}

- (void)remove
{
    @throw @"this method has to be over written.";
}

- (UIButton *)createTutorialSkipButton
{
    UIButton *skipButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [skipButton setTitle:@"チュートリアルをスキップ" forState:UIControlStateNormal];
    skipButton.frame = CGRectMake(0, 0, 160, 44);
    skipButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    skipButton.titleLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    skipButton.titleLabel.minimumFontSize = 12;
    skipButton.titleLabel.lineBreakMode = UILineBreakModeTailTruncation;
    [skipButton addTarget:self action:@selector(skipTutorial) forControlEvents:UIControlEventTouchUpInside];
    [skipButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    return skipButton;
}

- (void)skipTutorial
{
    // tutorial stageを進める
    [Tutorial forwardTutorialStageToLast];
    
    // overlayを消す
    [self remove];
    
    // パートをアップに変更 TODO 失敗した時どうしようかな
    [FamilyRole switchRole:@"uploader"];
    
    // こどもがbabyryちゃんの場合は情報を削除
    //    かつこども追加viewを表示(ViewControllerがやってくれる)
    NSString *tutorialChildObjectId = [Tutorial getTutorialAttributes:@"tutorialChildObjectId"];
    ViewController *vc = [self.targetViewController.navigationController.viewControllers objectAtIndex:0];
    NSMutableArray *childProperties = [ChildProperties getChildProperties];
    
    NSPredicate *p = [NSPredicate predicateWithFormat:@"objectId = %@", tutorialChildObjectId];
    NSArray *tutorialChildObjects = [childProperties filteredArrayUsingPredicate:p];
    if (tutorialChildObjects.count > 0) {
        for (NSMutableDictionary *matchedChild in tutorialChildObjects) {
            [ChildProperties deleteByObjectId:matchedChild[@"objectId"]];
        }
    }
    // _pageViewControllerを再読み込み
    NSNotification *n = [NSNotification notificationWithName:@"childPropertiesChanged" object:nil];
    [[NSNotificationCenter defaultCenter] postNotification:n];
   
    
    if ([self.targetViewController.navigationController viewControllers].count > 1) {
        [self.targetViewController.navigationController popToRootViewControllerAnimated:YES];
    } else {
        [vc viewDidAppear:YES];
    }
}

@end
