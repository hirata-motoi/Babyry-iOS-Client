//
//  PageContentViewController+Logic+Tutorial.m
//  babyry
//
//  Created by hirata.motoi on 2014/09/16.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "PageContentViewController+Logic+Tutorial.h"
#import "DateUtils.h"
#import "TutorialBestShot.h"
#import "Tutorial.h"
#import "TutorialStage.h"
#import "Config.h"
#import "TutorialFamilyApplyIntroduceView.h"
#import "TutorialReceivedApplyView.h"
#import "TutorialSentApplyView.h"
#import "ImageCache.h"
#import "PartnerApply.h"
#import "PartnerInvitedEntity.h"
#import "ColorUtils.h"

@implementation PageContentViewController_Logic_Tutorial {
    NSString *receivedApply;
    NSString *sentApply;
    
}

- (void)setImages
{
    [self showChildImages];
    [self setupImagesCount];
    [self setupNotificationHistory];
}

- (void)showChildImages
{
    // 固定でbabyryちゃんのデータを取得
    [self getChildImagesWithYear:0 withMonth:0 withReload:YES];
   
    self.pageContentViewController.dateComp = [self dateComps];
}

- (void)compensateDateOfChildImage:(NSArray *)childImages
{
    if (childImages.count < 1) {
        return;
    }
    // 取得したchildImagesのdateを現在の日付に補正する
    
    // childImagesを日付のdescでsort
    NSArray *sortedChildImages = [childImages sortedArrayUsingComparator:^(id obj1, id obj2) {
        return [obj2[@"date"] compare:obj1[@"date"]];
    }];
    
    // Parseの画像のうち最新のものの日付と現在の日時の差を出す = 全てのchildImageの日付をこの差で補正していく
    NSNumber *latestYMDOfDefaultImage = sortedChildImages[0][@"date"];
    NSDateComponents *defaultImageComps = [DateUtils compsFromNumber:latestYMDOfDefaultImage];
    NSDateComponents *todayComps = [self dateComps];

    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *diffDays = [calendar
                                  components:NSDayCalendarUnit
                                  fromDate:[calendar dateFromComponents:defaultImageComps]
                                  toDate:[calendar dateFromComponents:todayComps]
                                  options:0];
    
    for (PFObject *childImage in childImages) {
        NSDateComponents *comps = [DateUtils compsFromNumber:childImage[@"date"]];
        NSDateComponents *compensatedComps = [DateUtils addDateComps:comps withUnit:@"day" withValue:diffDays.day];
        childImage[@"date"] = [DateUtils numberFromComps:compensatedComps];
    }
}

// 今日の画像はTutorialBestShotに保存してあるBestShot情報を利用する
- (void)compensateBestFlagOfChildImage:(NSArray *)childImages
{
    // 今日
    NSDateComponents *todayComps = [DateUtils dateCompsFromDate:[NSDate date]];
    NSNumber *todayYMD = [NSNumber numberWithInteger:[[NSString stringWithFormat:@"%ld%02ld%02ld", todayComps.year, todayComps.month, todayComps.day] integerValue]];
    TutorialBestShot *todayBestShot = [TutorialBestShot MR_findFirst];
   
    for (PFObject *childImage in childImages) {
        if ([childImage.objectId isEqualToString:todayBestShot.imageObjectId]) {
            childImage[@"bestFlag"] = @"choosed";
        }
    }
    
}

- (NSDateComponents *)compsFromNumber:(NSNumber *)date
{
    NSString *ymdString = [date stringValue];
    NSString *year  = [ymdString substringWithRange:NSMakeRange(0, 4)];
    NSString *month = [ymdString substringWithRange:NSMakeRange(4, 2)];
    NSString *day   = [ymdString substringWithRange:NSMakeRange(6, 2)];
    
    NSDateComponents *comps = [[NSDateComponents alloc]init];
    comps.year  = [year integerValue];
    comps.month = [month integerValue];
    comps.day   = [day integerValue];
    
    return comps;
}

- (NSNumber *)numberFromComps:(NSDateComponents *)comps
{
    NSString *string = [NSString stringWithFormat:@"%ld%02ld%02ld", comps.year, comps.month, comps.day];
    return [NSNumber numberWithInt:[string intValue]];
}

- (void)showIntroductionOfImageRequest
{}

- (BOOL)forbiddenSelectCell:(NSIndexPath *)indexPath
{
    TutorialStage *currentStage = [Tutorial currentStage];
    NSArray *tutorialStages = [Config config][@"tutorialStages"];
    
    // tutorial第一ステージ以外はタップ可能
    if (![currentStage.currentStage isEqualToString:tutorialStages[0]]) {
        return NO;
    }
   
    // 1つ目のcellはタップ可能
    if (indexPath.section == 0 && indexPath.row == 0) {
        return NO;
    }
    return YES;
}

- (void)finalizeProcess
{
    [self.pageContentViewController.tn removeNavigationView];
    self.pageContentViewController.tn = [[TutorialNavigator alloc]init];
    self.pageContentViewController.tn.targetViewController = self.pageContentViewController;
    [self.pageContentViewController.tn showNavigationView];
}

- (void)setupHeaderView
{
    TutorialStage *currentStage = [Tutorial currentStage];
    if ([currentStage.currentStage isEqualToString:@"familyApply"] || [currentStage.currentStage isEqualToString:@"familyApplyExec"]) {
        if (![PartnerApply linkComplete]) {
            [self showFamilyApplyIntroduceView];
        } else {
            [self hideFamilyApplyIntroduceView];
        }
    } else {
        [self hideFamilyApplyIntroduceView];
    }
}


- (void)showFamilyApplyIntroduceView
{
    PageContentViewController *vc = self.pageContentViewController;
    if (!vc.familyApplyIntroduceView) {
        TutorialFamilyApplyIntroduceView *headerView = [TutorialFamilyApplyIntroduceView view];
        [headerView.openFamilyApplyButton addTarget:vc action:@selector(openFamilyApply) forControlEvents:UIControlEventTouchUpInside];
        vc.familyApplyIntroduceView = headerView;
        [self setRectToHeaderView:vc.familyApplyIntroduceView];
        
        // パートナー申請誘導viewの分collection viewを小さくする
        CGRect collectionRect = vc.pageContentCollectionView.frame;
        collectionRect.size.height = collectionRect.size.height - vc.familyApplyIntroduceView.frame.size.height;
        collectionRect.origin.y = collectionRect.origin.y + vc.familyApplyIntroduceView.frame.size.height;
        vc.pageContentCollectionView.frame = collectionRect;
        
        [vc.view addSubview:vc.familyApplyIntroduceView];
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
                [self switchHeaderView:vc];
                return;
            }];
            
            PartnerInvitedEntity *pie = [PartnerInvitedEntity MR_findFirst];
            if (!pie){
                sentApply = @"NO";
                [self switchHeaderView:vc];
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
                [self switchHeaderView:vc];
                return;
            }];
        }
    }];
}

- (void)setRectToHeaderView:(UIView *)headerView
{
    CGRect rect = headerView.frame;
    rect.origin.x = 0;
    rect.origin.y = 64;
    headerView.frame = rect;
}

- (void)switchHeaderView:(PageContentViewController *)vc
{
    if (receivedApply == nil || sentApply == nil) {
        return;
    }
    
    if ([receivedApply isEqualToString:@"YES"]) {
        // viewを「申請がきています」viewに変更
        TutorialReceivedApplyView *headerView = [TutorialReceivedApplyView view];
        [headerView.openReceivedApplyButton addTarget:vc action:@selector(openFamilyApplyList) forControlEvents:UIControlEventTouchUpInside];
        [vc.familyApplyIntroduceView removeFromSuperview];
        vc.familyApplyIntroduceView = nil;
        vc.familyApplyIntroduceView = headerView;
        [self setRectToHeaderView:vc.familyApplyIntroduceView];
        [vc.view addSubview:vc.familyApplyIntroduceView];
        return;
    }
    if ([sentApply isEqualToString:@"YES"]) {
        // viewを 「承認待ちです」viewに変更
        TutorialSentApplyView *headerView = [TutorialSentApplyView view];
        [headerView.openPartnerApplyListButton addTarget:vc action:@selector(openPartnerWait) forControlEvents:UIControlEventTouchUpInside];
        [vc.familyApplyIntroduceView removeFromSuperview];
        vc.familyApplyIntroduceView = nil;
        vc.familyApplyIntroduceView = headerView;
        [self setRectToHeaderView:vc.familyApplyIntroduceView];
        [vc.view addSubview:vc.familyApplyIntroduceView];
        return;
    }
    // viewを「パートナーと始める」viewに変更
    TutorialFamilyApplyIntroduceView *headerView = [TutorialFamilyApplyIntroduceView view];
    [headerView.openFamilyApplyButton addTarget:vc action:@selector(openFamilyApply) forControlEvents:UIControlEventTouchUpInside];
    [vc.familyApplyIntroduceView removeFromSuperview];
    vc.familyApplyIntroduceView = nil;
    vc.familyApplyIntroduceView = headerView;
    [self setRectToHeaderView:vc.familyApplyIntroduceView];
    [vc.view addSubview:vc.familyApplyIntroduceView];
    
    TutorialStage *currentStage = [Tutorial currentStage];
    if ([currentStage.currentStage isEqualToString:@"familyApply"]) {
        [self.pageContentViewController showTutorialNavigator];
    }
}

- (void)getChildImagesWithYear:(NSInteger)year withMonth:(NSInteger)month withReload:(BOOL)reload
{
    // 画像のリストを生成する
    // [ { date => yyyymmdd, images => {filename => $filename, bestFlag => 1}, ...}, ....]
    NSMutableArray *dateList = [self dateList];
    NSMutableArray *imagesSource = [NSMutableArray arrayWithArray: [Config config][@"TutorialImages"]];
    
    NSInteger index = [[self.pageContentViewController.childImagesIndexMap objectForKey:[NSString stringWithFormat:@"%ld%02ld", (long)year, (long)month]] integerValue];
    NSMutableDictionary *section = [self.pageContentViewController.childImages objectAtIndex:index];
    NSMutableArray *images = [section objectForKey:@"images"];
    NSMutableArray *totalImageNum = [section objectForKey:@"totalImageNum"];
    
    int i = 0;
    for (NSMutableDictionary *imageSource in imagesSource) {
        NSNumber *date = dateList[i];
        
        // totalImageNumの設定
        totalImageNum[i] = [NSNumber numberWithInteger:[imageSource[@"images"] count]];
                                                   
        
        for (NSMutableDictionary *imageDic in imageSource[@"images"]) {
            if (!imageDic[@"bestFlag"]) {
                continue;
            }
            NSString *imageFileName = imageDic[@"imageFileName"];
            UIImage *imageThumbnail = [ImageCache makeThumbNail:[UIImage imageNamed:imageFileName]];
            NSData *imageThumbnailData = [[NSData alloc] initWithData:UIImageJPEGRepresentation(imageThumbnail, 1.0f)];
           [ImageCache setCache:[date stringValue] image:imageThumbnailData dir:[NSString stringWithFormat:@"%@/bestShot/thumbnail", self.pageContentViewController.childObjectId]];
        }
        i++;
    }
    
    self.pageContentViewController.isLoading = NO;
    [self.pageContentViewController.hud hide:YES];
    self.pageContentViewController.isFirstLoad = 0;
}

- (NSMutableArray *)dateList
{
    NSMutableArray *dateList = [[NSMutableArray alloc]init];
    NSDateComponents *comps = [DateUtils dateCompsFromDate:[NSDate date]];
    
    for (NSInteger i = 0; i < 7; i++) {
        NSString *dateStr = [NSString stringWithFormat:@"%ld%02ld%02ld", comps.year, comps.month, comps.day];
        NSNumber *date = [NSNumber numberWithInteger:[dateStr integerValue]];
        [dateList addObject:date];
        
        comps = [DateUtils addDateComps:comps withUnit:@"day" withValue:-1];
    }
    return dateList;
}

- (void)forwardNextTutorial
{
    [Tutorial forwardStageWithNextStage:@"familyApply"];
    [self setupHeaderView];
    [self.pageContentViewController viewDidAppear:YES];
    [self.pageContentViewController showTutorialNavigator];
}

// Tutorial中はnotification出さない
- (void)setupNotificationHistory
{}

@end
