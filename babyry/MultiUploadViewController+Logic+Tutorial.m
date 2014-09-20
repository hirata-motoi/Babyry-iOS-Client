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
#import "TutorialStage.h"
#import "Config.h"

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
    
    NSDateComponents *currentComps = [DateUtils compsFromNumber:currentDate];
    NSDateComponents *defaultImageComps = [DateUtils compsFromNumber:latestDateOfDefaultImage];
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *diffDays = [calendar
                                  components:NSDayCalendarUnit
                                  fromDate:[calendar dateFromComponents:defaultImageComps]
                                  toDate:[calendar dateFromComponents:currentComps]
                                  options:0];
    for (PFObject *childImage in childImages) {
        NSDateComponents *comps = [DateUtils compsFromNumber:childImage[@"date"]];
        NSDateComponents *compensatedComps = [DateUtils addDateComps:comps withUnit:@"day" withValue:diffDays.day];
        childImage[@"date"] = [DateUtils numberFromComps:compensatedComps];
    }
}

- (void)compensateBestImageId:(NSArray *)childImages
{
    TutorialBestShot *tutorialBestShot = [TutorialBestShot MR_findFirst];
    if (!tutorialBestShot) {
        return;
    }
    
    self.multiUploadViewController.bestImageId = tutorialBestShot.imageObjectId;
}

- (void)updateBestShot
{
    TutorialBestShot *tutorialBestShot = [TutorialBestShot MR_findFirst];
    if (!tutorialBestShot) {
        tutorialBestShot = [TutorialBestShot MR_createEntity];
    }
    tutorialBestShot.imageObjectId = self.multiUploadViewController.bestImageId;
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    
    [Tutorial updateStage];
}

- (void)prepareForTutorial:(UICollectionViewCell *)cell withIndexPath:(NSIndexPath *)indexPath
{
    [self removeGestureForTutorial:cell];
    
    if (indexPath.row == 0) {
        [self.multiUploadViewController showTutorialNavigator];
    }
}

- (void)removeGestureForTutorial:(UICollectionViewCell *)cell
{
    TutorialStage *currentStage = [Tutorial currentStage];
    
    if (![currentStage.currentStage isEqualToString:@"chooseByUser"]) {
        return;
    }
    for (UITapGestureRecognizer *gesture in [cell gestureRecognizers]) {
        if([gesture isKindOfClass:[UITapGestureRecognizer class]]) {
            [cell removeGestureRecognizer:gesture];
        }
    }
}

- (void)finalizeProcess
{
    [self.multiUploadViewController.navigationController popViewControllerAnimated:YES];
}

@end
