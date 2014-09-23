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
#import "ImageCache.h"

@implementation MultiUploadViewController_Logic_Tutorial

-(void)updateImagesFromParse
{
    // デフォルトの画像からcandidateにcacheを作る
    // totalImageNumは変更不要
    // childImageArrayがどう使われてるのか調べる -> cell数得るのとopenImagePageViewだけ
    NSMutableArray *imagesSource = [Config config][@"TutorialImages"];
    NSMutableDictionary *source = imagesSource[0];
    
    for (NSMutableDictionary *imageDic in source[@"images"]) {
        NSString *imageFileName = imageDic[@"imageFileName"];
        
        UIImage *image = [UIImage imageNamed:imageFileName];
        NSData *imageThumbnailData = [[NSData alloc] initWithData:UIImageJPEGRepresentation(image, 0.7f)];
        NSData *imageFullsizeData = [[NSData alloc] initWithData:UIImageJPEGRepresentation(image, 1.0f)];
        [ImageCache setCache:imageFileName image:imageThumbnailData dir:[NSString stringWithFormat:@"%@/candidate/%@/thumbnail", self.multiUploadViewController.childObjectId, self.multiUploadViewController.date]];
        [ImageCache setCache:imageFileName image:imageFullsizeData dir:[NSString stringWithFormat:@"%@/candidate/%@/fullsize", self.multiUploadViewController.childObjectId, self.multiUploadViewController.date]];
    }
    
    self.multiUploadViewController.childImageArray = source[@"images"]; // ほんとはPFObjectの配列を入れるべきだが、tutorial中はchildImageArray.countしかみないのでこれでよし
    
    self.multiUploadViewController.imageLoadComplete = YES;
    [self.multiUploadViewController.hud hide:YES];
    [self showCacheImages];
}

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
    
    [Tutorial forwardStageWithNextStage:@"partChange"];
}

- (void)prepareForTutorial:(UICollectionViewCell *)cell withIndexPath:(NSIndexPath *)indexPath
{
    [self removeGestureForTutorial:cell];
    
    if (indexPath.row == 0) {
        // このmethodが呼ばれるのはcellがまだ表示されていないタイミング。なので期待する位置にholeが表示されない
        // ほんとはcellが表示された時点でblockを実行するような実装にすべきだがちょと手間なのでtimer使う
        [NSTimer scheduledTimerWithTimeInterval:0.3 target:self.multiUploadViewController selector:@selector(showTutorialNavigator) userInfo:nil repeats:NO];
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
