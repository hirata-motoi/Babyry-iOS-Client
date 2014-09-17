//
//  MultiUploadViewController+Logic+Tutorial.m
//  babyry
//
//  Created by hirata.motoi on 2014/09/16.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "MultiUploadViewController+Logic+Tutorial.h"
#import "DateUtils.h"
#import "TutorialBestShot.h"
#import "Tutorial.h"

@implementation MultiUploadViewController_Logic_Tutorial

// TODO ベタ書きはやめる
- (NSNumber *)compensateTargetDate:(NSNumber *)date
{
    NSNumber *compensatedDate;
    if (self.multiUploadViewController.indexPath.row == 0) {
        compensatedDate = [NSNumber numberWithInt:20140831];
    } else if (self.multiUploadViewController.indexPath.row == 1) {
        compensatedDate = [NSNumber numberWithInt:20140830];
    }
    return compensatedDate;
}

- (void)compensateDateOfChildImage:(NSArray *)childImages
{
    if (childImages.count < 1) {
        return;
    }
    
    NSNumber *currentDate = [NSNumber numberWithInteger:[self.multiUploadViewController.date integerValue]];
    NSNumber *latestDateOfDefaultImage = childImages[0][@"date"];
    
    NSDateComponents *currentComps = [self compsFromNumber:currentDate];
    NSDateComponents *defaultImageComps = [self compsFromNumber:latestDateOfDefaultImage];
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *diffDays = [calendar
                                  components:NSDayCalendarUnit
                                  fromDate:[calendar dateFromComponents:defaultImageComps]
                                  toDate:[calendar dateFromComponents:currentComps]
                                  options:0];
    for (PFObject *childImage in childImages) {
        NSDateComponents *comps = [self compsFromNumber:childImage[@"date"]];
        NSDateComponents *compensatedComps = [DateUtils addDateComps:comps withUnit:@"day" withValue:diffDays.day];
        childImage[@"date"] = [self numberFromComps:compensatedComps];
    }
}

- (void)compensateBestImageId:(NSArray *)childImages
{
    NSNumber *currentDate = [NSNumber numberWithInteger:[self.multiUploadViewController.date integerValue]];
    TutorialBestShot *tutorialBestShot = [TutorialBestShot MR_findFirst];
    if (!tutorialBestShot) {
        return;
    }
    
    self.multiUploadViewController.bestImageId = tutorialBestShot.imageObjectId;
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

- (void)updateBestShot
{
    NSNumber *currentDate = [NSNumber numberWithInteger:[self.multiUploadViewController.date integerValue]];
    TutorialBestShot *tutorialBestShot = [TutorialBestShot MR_findFirst];
    if (!tutorialBestShot) {
        tutorialBestShot = [TutorialBestShot MR_createEntity];
    }
    tutorialBestShot.imageObjectId = self.multiUploadViewController.bestImageId;
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    
    [Tutorial updateStage];
}

@end
