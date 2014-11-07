    //
//  HeaderViewManager.m
//  babyry
//
//  Created by hirata.motoi on 2014/11/04.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "HeaderViewManager.h"
#import "Tutorial.h"
#import "TutorialStage.h"
#import "PartnerApply.h"
#import "PartnerInvitedEntity.h"
#import "FamilyRole.h"

@implementation HeaderViewManager {
    NSString *currentHeaderViewClass;
    NSString *receivedApply;
    NSString *sentApply;
    NSTimer *timer;
}

- (id)init
{
    if (self = [super init]) {
        if ([[Tutorial currentStage].currentStage isEqualToString:@"familyApplyExec"]) {
            [self validateTimer];
        }
    }
    return self;
}

- (void)checkPartnerApplyStatus
{
    if ([[Tutorial currentStage].currentStage isEqualToString:@"tutorialFinished"]) {
        [self invalidateTimer];
    }
    [FamilyRole updateCacheWithBlock:^(void) {
        [self setupHeaderView:YES];
    }];
}


- (void)setupHeaderView:(BOOL)doBackground
{
    TutorialStage *currentStage = [Tutorial currentStage];
    if ([currentStage.currentStage isEqualToString:@"familyApply"] || [currentStage.currentStage isEqualToString:@"familyApplyExec"]) {
        if (![PartnerApply linkComplete]) {
            [self showFamilyApplyIntroduceView:doBackground];
        } else {
            [self hideFamilyApplyIntroduceView];
        }
    } else {
        [self hideFamilyApplyIntroduceView];
    }
}

- (void)showFamilyApplyIntroduceView:(BOOL)doBackground
{
    // familyApplyの時は即表示
    if ([[Tutorial currentStage].currentStage isEqualToString:@"familyApply"]) {
        receivedApply = @"NO";
        sentApply = @"NO";
        [self switchHeaderView];
        return;
    }
   
    if (!doBackground) {
        PartnerInvitedEntity *pie = [PartnerInvitedEntity MR_findFirst];
        sentApply = (pie) ? @"YES" : @"NO";
        receivedApply = @"NO"; // これはParseを参照しないとわからない
        [self switchHeaderView];
        return;
    }
    
    [[PFUser currentUser] refreshInBackgroundWithBlock:^(PFObject *object, NSError *error){
        if (object) {
            
            // initialize
            receivedApply = nil;
            sentApply = nil;
            
            PFQuery *applyList = [PFQuery queryWithClassName:@"PartnerApplyList"];
            [applyList whereKey:@"familyId" equalTo:object[@"familyId"]];
            [applyList findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
                if ([objects count] > 0) {
                    receivedApply = @"YES";
                } else {
                    receivedApply = @"NO";
                }
                [self switchHeaderView];
                return;
            }];
            
            PartnerInvitedEntity *pie = [PartnerInvitedEntity MR_findFirst];
            if (!pie){
                sentApply = @"NO";
                [self switchHeaderView];
                return;
            }
            PFQuery *applyByMe = [PFQuery queryWithClassName:@"PartnerApplyList"];
            [applyByMe whereKey:@"familyId" equalTo:pie.familyId];
            [applyByMe findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
                if ([objects count] > 0) {
                    sentApply = @"YES";
                } else {
                    sentApply = @"NO";
                }
                [self switchHeaderView];
                return;
            }];
        }
    }];
}

- (void)hideFamilyApplyIntroduceView
{
    [_delegate hideHeaderView];
}

- (void)setRectToHeaderView:(UIView *)headerView
{
    CGRect rect = headerView.frame;
    rect.origin.x = 0;
    rect.origin.y = 64;
    headerView.frame = rect;
}

- (void)switchHeaderView
{
    if (receivedApply == nil || sentApply == nil) {
        // まだデータ取得が完了していない時
        return;
    }
    
    if ([receivedApply isEqualToString:@"YES"]) {
        [_delegate showHeaderView:@"receivedApply"];
        return;
    }
    if ([sentApply isEqualToString:@"YES"]) {
        [_delegate showHeaderView:@"sentApply"];
        return;
    }
    [_delegate showHeaderView:@"familyApplyIntroduce"];
}

- (void)invalidateTimer
{
    [timer invalidate];
}

- (void)validateTimer
{
    if (!timer || ![timer isValid]) {
        timer = [NSTimer scheduledTimerWithTimeInterval:10.0f target:self selector:@selector(checkPartnerApplyStatus) userInfo:nil repeats:YES];
    }
}

@end
