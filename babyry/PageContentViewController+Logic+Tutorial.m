//
//  PageContentViewController+Logic+Tutorial.m
//  babyry
//
//  Created by hirata.motoi on 2014/09/16.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "PageContentViewController+Logic+Tutorial.h"
#import "DateUtils.h"

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
    
    // 最新の日付と現在日時の差を出す = 全てのchildImageの日付をこの差で補正していく
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

@end
