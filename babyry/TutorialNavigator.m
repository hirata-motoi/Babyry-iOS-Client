//
//  TutorialNavigator.m
//  babyry
//
//  Created by hirata.motoi on 2014/09/17.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "TutorialNavigator.h"
#import "TutorialStage.h"
#import "TutorialNavigator+ShowMultiUpload.h"
#import "TutorialNavigator+SelectBestShot.h"
#import "TutorialNavigator+PartChange.h"
#import "TutorialNavigator+PartChangeExec.h"
#import "TutorialNavigator+AddChild.h"
#import "TutorialNavigator+AddChildExec.h"
#import "TutorialNavigator+UploadByUser.h"
#import "TutorialNavigator+TutorialFinished.h"
#import "Config.h"
#import "PageContentViewController.h"
#import "MultiUploadViewController.h"
#import "GlobalSettingViewController.h"
#import "IntroChildNameViewController.h"

@implementation TutorialNavigator {
    TutorialNavigator *navigator_;
}

- (void)showNavigationView
{
    TutorialStage *stage = [TutorialStage MR_findFirst];
    if (!stage) {
        return;
    }
    
    if ([stage.currentStage isEqualToString:@"chooseByUser"]) {
        if ([_targetViewController isKindOfClass:[PageContentViewController class]]) {
            TutorialNavigator_ShowMultiUpload *navigator = [[TutorialNavigator_ShowMultiUpload alloc]init];
            navigator.targetViewController = _targetViewController;
            [navigator show];
            navigator_ = navigator;
        } else if ([_targetViewController isKindOfClass:[MultiUploadViewController class]]) {
            TutorialNavigator_SelectBestShot *navigator = [[TutorialNavigator_SelectBestShot alloc]init];
            navigator.targetViewController = _targetViewController;
            [navigator show];
            navigator_ = navigator;
        }
    } else if ([stage.currentStage isEqualToString:@"partChange"]) {
        if ([_targetViewController isKindOfClass:[PageContentViewController class]]) {
            TutorialNavigator_PartChange *navigator = [[TutorialNavigator_PartChange alloc]init];
            navigator.targetViewController = _targetViewController;
            [navigator show];
            navigator_ = navigator;
        } else if ([_targetViewController isKindOfClass:[GlobalSettingViewController class]]) {
            TutorialNavigator_PartChangeExec *navigator = [[TutorialNavigator_PartChangeExec alloc]init];
            navigator.targetViewController = _targetViewController;
            [navigator show];
            navigator_ = navigator;
        }
    } else if ([stage.currentStage isEqualToString:@"addChild"]) {
        if ([_targetViewController isKindOfClass:[GlobalSettingViewController class]]) {
            TutorialNavigator_AddChild *navigator = [[TutorialNavigator_AddChild alloc]init];
            navigator.targetViewController = _targetViewController;
            [navigator show];
            navigator_ = navigator;
        } else if ([_targetViewController isKindOfClass:[IntroChildNameViewController class]]) {
            TutorialNavigator_AddChildExec *navigator = [[TutorialNavigator_AddChildExec alloc]init];
            navigator.targetViewController = _targetViewController;
            [navigator show];
            navigator_ = navigator;
        }
    } else if ([stage.currentStage isEqualToString:@"uploadByUser"]) {
        if ([_targetViewController isKindOfClass:[PageContentViewController class]]) {
            TutorialNavigator_UploadByUser *navigator = [[TutorialNavigator_UploadByUser alloc]init];
            navigator.targetViewController = _targetViewController;
            [navigator show];
            navigator_ = navigator;
        }
    } else if ([stage.currentStage isEqualToString:@"tutorialFinished"]) {
        if ([_targetViewController isKindOfClass:[PageContentViewController class]]) {
            TutorialNavigator_TutorialFinished *navigator = [[TutorialNavigator_TutorialFinished alloc]init];
            navigator.targetViewController = _targetViewController;
            [navigator show];
            navigator_ = navigator;
        }
    }
}

- (void)removeNavigationView
{
    [navigator_ remove];
}

- (void)remove
{
    @throw @"this method has to be over written.";
}

@end
