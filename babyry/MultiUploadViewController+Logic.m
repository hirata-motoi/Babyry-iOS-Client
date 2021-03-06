//
//  MultiUploadViewController+Logic.m
//  babyry
//
//  Created by hirata.motoi on 2014/09/16.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "MultiUploadViewController+Logic.h"
#import "MultiUploadViewController.h"
#import "ImageCache.h"
#import "Logger.h"
#import "Config.h"
#import "Partner.h"
#import "PushNotification.h"
#import "NotificationHistory.h"
#import "DateUtils.h"
#import "ChildProperties.h"
#import "AWSS3Utils.h"
#import "ImageUploadInBackground.h"

@implementation MultiUploadViewController_Logic

- (void) showCacheImages
{
    // その日のcandidate画像数のファイル名を返せばいい
    _multiUploadViewController.childCachedImageArray = [[NSMutableArray alloc] initWithArray:[ImageCache getListOfMultiUploadCache:[NSString stringWithFormat:@"%@/candidate/%@/thumbnail", _multiUploadViewController.childObjectId, _multiUploadViewController.date]]];
    [_multiUploadViewController.multiUploadedImages reloadData];
}

-(void)updateImagesFromParse
{
    // Parseから画像をとる
    // TODO 子クラスでは日付を調節して取得してくる。_dateの値を書き換えるだけでいいかもしれない
    // また、CoreDataからBestShotの情報を取得して_bestImageIdをセットする。このmethodの後の方でいいかも
    NSMutableDictionary *childProperty = [ChildProperties getChildProperty:self.multiUploadViewController.childObjectId];
    PFQuery *childImageQuery = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%ld", (long)[childProperty[@"childImageShardIndex"] integerValue]]];
    childImageQuery.cachePolicy = kPFCachePolicyNetworkOnly;
    [childImageQuery whereKey:@"imageOf" equalTo:_multiUploadViewController.childObjectId];
    [childImageQuery whereKey:@"date" equalTo:[self compensateTargetDate:[NSNumber numberWithInteger:[_multiUploadViewController.date integerValue]]]];
    [childImageQuery orderByAscending:@"createdAt"];
    [childImageQuery whereKey:@"isTmpData" notEqualTo:@"TRUE"];
    [childImageQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if(!error) {
            
            int uploadingQueueCount = [ImageUploadInBackground getUploadingQueueCount];
            [_multiUploadViewController.totalImageNum replaceObjectAtIndex:_multiUploadViewController.indexPath.row withObject:[NSNumber numberWithInteger:objects.count + uploadingQueueCount]];
            
            [self compensateDateOfChildImage:objects];
            [self compensateBestImageId:objects];
            
            // objectにあるけどキャッシュに無い = 新しい画像
            NSMutableArray *downloadQueue = [[NSMutableArray alloc] init];
            for (PFObject *object in objects) {
                if ([object[@"bestFlag"] isEqualToString:@"choosed"]) {
                    _multiUploadViewController.bestImageId = object.objectId;
                }
                if (![ImageCache getCache:object.objectId dir:[NSString stringWithFormat:@"%@/candidate/%@/thumbnail", _multiUploadViewController.childObjectId, _multiUploadViewController.date]]) {
                    NSMutableDictionary *queue = [[NSMutableDictionary alloc] init];
                    queue[@"objectId"] = object.objectId;
                    queue[@"childObjectId"] = _multiUploadViewController.childObjectId;
                    queue[@"date"] = object[@"date"];
                    queue[@"isCandidate"] = [NSNumber numberWithBool:YES];
                    [downloadQueue addObject:queue];
                }
            }
            // キャッシュにあるけどobjectにない = 消された画像
            for (NSString *cache in _multiUploadViewController.childCachedImageArray) {
                BOOL isExist = NO;
                for (PFObject *object in objects) {
                    if ([cache isEqualToString:object.objectId]) {
                        isExist = YES;
                    }
                }
                if (!isExist) {
                    [ImageCache removeCache:[NSString stringWithFormat:@"%@/candidate/%@/thumbnail/%@", _multiUploadViewController.childObjectId, _multiUploadViewController.date, cache]];
                    [ImageCache removeCache:[NSString stringWithFormat:@"%@/candidate/%@/fullsize/%@", _multiUploadViewController.childObjectId, _multiUploadViewController.date, cache]];
                }
            }
            
            // 注意 : ここは深いコピーをしないとだめ
            _multiUploadViewController.childImageArray = [[NSMutableArray alloc] initWithArray:objects];
            
            //再起的にgetDataしてキャッシュを保存する
            //_multiUploadViewController.tmpCacheCount = 0;
            
            _multiUploadViewController.imageLoadComplete = NO;
            
            if ([downloadQueue count] > 0) {
                [self setCacheOfParseImage:downloadQueue];
            } else {
                [self completeSetCache];
            }
        } else {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in getting Image Data from Parse : %@", error]];
        }
    }];
    
    // 不要なdirの削除
    [self removePastCandidateDir];
}

- (void)compensateBestImageId:(NSArray *)childImages
{}

-(void)setCacheOfParseImage:(NSMutableArray *)downloadQueue
{
    AWSS3Utils *awsS3Utils = [[AWSS3Utils alloc] init];
    [awsS3Utils makeCacheFromS3:downloadQueue configuration:_multiUploadViewController.configuration withBlock:^(void){
        [self completeSetCache];
    }];
}

- (void) completeSetCache
{
    _multiUploadViewController.imageLoadComplete = YES;
    [self showCacheImages];
    
    if (![ImageUploadInBackground getIsUploading]) {
        _multiUploadViewController.needTimer = NO;
        [_multiUploadViewController.myTimer invalidate];
    }
    
    _multiUploadViewController.isTimperExecuting = NO;
}

- (void)updateBestShot
{
    // update Parse
    NSMutableDictionary *childProperty = [ChildProperties getChildProperty:self.multiUploadViewController.childObjectId];
    PFQuery *childImageQuery = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%ld", (long)[childProperty[@"childImageShardIndex"] integerValue]]];
    childImageQuery.cachePolicy = kPFCachePolicyNetworkOnly;
    [childImageQuery whereKey:@"imageOf" equalTo:_multiUploadViewController.childObjectId];
    [childImageQuery whereKey:@"date" equalTo:[NSNumber numberWithInteger:[_multiUploadViewController.date integerValue]]];
    [childImageQuery orderByAscending:@"createdAt"];
    [childImageQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(!error) {
            int index = 0;
            for (PFObject *object in objects) {
                if ([object.objectId isEqualToString:_multiUploadViewController.bestImageId]) {
                    if (![object[@"bestFlag"] isEqualToString:@"choosed"]) {
                        object[@"bestFlag"] =  @"choosed";
                        [object saveInBackground];
                    }
                } else {
                    if (![object[@"bestFlag"] isEqualToString:@"unchoosed"]) {
                        object[@"bestFlag"] =  @"unchoosed";
                        [object saveInBackground];
                    }
                }
                index++;
            }
            PFObject *partner = (PFUser *)[Partner partnerUser];
            if (partner != nil) {
                NSMutableDictionary *transitionInfoDic = [[NSMutableDictionary alloc] init];
                transitionInfoDic[@"event"] = @"bestShotChosen";
                transitionInfoDic[@"date"] = self.multiUploadViewController.date;
                transitionInfoDic[@"section"] = [NSString stringWithFormat:@"%d", self.multiUploadViewController.indexPath.section];
                transitionInfoDic[@"row"] = [NSString stringWithFormat:@"%d", self.multiUploadViewController.indexPath.row];
                transitionInfoDic[@"childObjectId"] = self.multiUploadViewController.childObjectId;
                NSMutableDictionary *options = [[NSMutableDictionary alloc]init];
                options[@"formatArgs"] = [NSArray arrayWithObject:[PFUser currentUser][@"nickName"]];
                options[@"data"] = [[NSMutableDictionary alloc]initWithObjects:@[@"Increment"] forKeys:@[@"badge"]];
                options[@"data"] = [[NSMutableDictionary alloc]
                                    initWithObjects:@[@"Increment", transitionInfoDic]
                                    forKeys:@[@"badge", @"transitionInfo"]];
                [PushNotification sendInBackground:@"bestShotChosen" withOptions:options];
                [self createNotificationHistory:@"bestShotChanged"];
            }
            
        } else {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in get images : %@", error]];
        }
    }];
    
}

- (void)updateBestShotWithChild:(NSString *)childObjectId withDate:(NSString *)date
{
    NSMutableDictionary *childProperty = [ChildProperties getChildProperty:childObjectId];
    PFQuery *childImageQuery = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%ld", [childProperty[@"childImageShardIndex"] integerValue]]];
    childImageQuery.cachePolicy = kPFCachePolicyNetworkOnly;
    [childImageQuery whereKey:@"imageOf" equalTo:childObjectId];
    [childImageQuery whereKey:@"date" equalTo:[NSNumber numberWithInteger:[date integerValue]]];
    [childImageQuery orderByAscending:@"createdAt"];
    [childImageQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in getting images during tutorial : %@", error]];
            return;
        }
        if (objects.count < 1) {
            return;
        }
        
        // ランダムでどれか1つをbestshotに選ぶ
        // TODO arc4random_uniformで得られる数値の範囲を確認
        int bestShotIndex = (int)arc4random_uniform((int)objects.count);
        // 最後の画像のsaveが終わった段階でdidUpdatedChildImageInfoを発行する用のindex
        int maxCount = objects.count;
        int __block execCount = 0;
        for (int i = 0; i < objects.count; i++) {
            PFObject *childImage = objects[i];
            childImage[@"bestFlag"] = (i == bestShotIndex) ? @"choosed" : @"unchoosed";
            [childImage saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                execCount++;
                if (execCount == maxCount) {
                    [[NSNotificationCenter defaultCenter] postNotification: [NSNotification notificationWithName:@"didUpdatedChildImageInfo" object:self]];
                }
            }];
        }
    }];
}

- (void)createNotificationHistory:(NSString *)type
{
    [NSThread detachNewThreadSelector:@selector(executeNotificationHistory:) toTarget:self withObject:[[NSMutableDictionary alloc]initWithObjects:@[type] forKeys:@[@"type"]]];
    
}

- (void)executeNotificationHistory:(id)param
{
    NSString *type = [param objectForKey:@"type"];
    PFObject *partner = (PFUser *)[Partner partnerUser];
    [NotificationHistory createNotificationHistoryWithType:type withTo:partner[@"userId"] withChild:_multiUploadViewController.childObjectId withDate:[_multiUploadViewController.date integerValue]];
}

// 昨日より前のcandidate dirは不要なので削除
- (void)removePastCandidateDir
{
    NSDateComponents *todayComps = [DateUtils dateCompsFromDate:nil];
    NSDateComponents *yesterdayComps = [DateUtils addDateComps:todayComps withUnit:@"day" withValue:-1];
    NSString *today = [NSString stringWithFormat:@"%ld%02ld%02ld", todayComps.year, todayComps.month, todayComps.day];
    NSString *yesterday = [NSString stringWithFormat:@"%ld%02ld%02ld", yesterdayComps.year, yesterdayComps.month, yesterdayComps.day];
    
    NSArray *dateDirList = [ImageCache getListOfMultiUploadCache:[NSString stringWithFormat:@"%@/candidate", _multiUploadViewController.childObjectId]];
    for (NSString *dirName in dateDirList) {
        if ( ![dirName isEqualToString:today] && ![dirName isEqualToString:yesterday] ) {
            [ImageCache removeCache:[NSString stringWithFormat:@"%@/candidate/%@", _multiUploadViewController.childObjectId, dirName]];
        }
    }
}

// imageUploaded, bestShotChanged, bestShotReplyはページを開いた時点で無効にする
- (void)disableNotificationHistory
{
    NSArray *targetTypes = [NSArray arrayWithObjects:@"imageUploaded", @"bestShotChanged", nil];
    [NotificationHistory disableDisplayedNotificationsWithUser:[PFUser currentUser][@"userId"] withChild:self.multiUploadViewController.childObjectId withDate:self.multiUploadViewController.date withType:targetTypes];
}

- (void)compensateDateOfChildImage:(NSArray *)childImages {}

- (NSNumber *)compensateTargetDate:(NSNumber *)date
{
    return date;
}

- (BOOL)isSelectedBestShot:(NSString *)bestImageId
{
    return [_multiUploadViewController.bestImageId isEqualToString:bestImageId];
}

- (void)prepareForTutorial:(UICollectionViewCell *)cell withIndexPath:(NSIndexPath *)indexPath
{}

- (void)finalizeSelectBestShot
{}

- (void)forwardNextTutorial
{}

@end
