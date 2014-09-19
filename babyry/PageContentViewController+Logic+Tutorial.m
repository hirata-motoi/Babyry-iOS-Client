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

@implementation PageContentViewController_Logic_Tutorial

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
    NSDateComponents *defaultImageComps = [self compsFromNumber:latestYMDOfDefaultImage];
    NSDateComponents *todayComps = [self dateComps];

    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *diffDays = [calendar
                                  components:NSDayCalendarUnit
                                  fromDate:[calendar dateFromComponents:defaultImageComps]
                                  toDate:[calendar dateFromComponents:todayComps]
                                  options:0];
    
    for (PFObject *childImage in childImages) {
        NSDateComponents *comps = [self compsFromNumber:childImage[@"date"]];
        NSDateComponents *compensatedComps = [DateUtils addDateComps:comps withUnit:@"day" withValue:diffDays.day];
        childImage[@"date"] = [self numberFromComps:compensatedComps];
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

@end
