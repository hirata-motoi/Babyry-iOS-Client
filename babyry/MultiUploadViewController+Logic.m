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
    PFQuery *childImageQuery = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%ld", (long)[_multiUploadViewController.child[@"childImageShardIndex"] integerValue]]];
    childImageQuery.cachePolicy = kPFCachePolicyNetworkOnly;
    [childImageQuery whereKey:@"imageOf" equalTo:_multiUploadViewController.childObjectId];
    [childImageQuery whereKey:@"date" equalTo:[self compensateTargetDate:[NSNumber numberWithInteger:[_multiUploadViewController.date integerValue]]]];
    [childImageQuery orderByAscending:@"createdAt"];
    [childImageQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if(!error) {
            [_multiUploadViewController.totalImageNum replaceObjectAtIndex:_multiUploadViewController.indexPath.row withObject:[NSNumber numberWithInteger:objects.count]];
            
            [self compensateDateOfChildImage:objects];
            [self compensateBestImageId:objects];
            
            // objectにあるけどキャッシュに無い = 新しい画像
            NSMutableArray *newImages = [[NSMutableArray alloc] init];
            for (PFObject *object in objects) {
                if ([object[@"bestFlag"] isEqualToString:@"choosed"]) {
                    _multiUploadViewController.bestImageId = object.objectId;
                }
                if (![ImageCache getCache:object.objectId dir:[NSString stringWithFormat:@"%@/candidate/%@/thumbnail", _multiUploadViewController.childObjectId, _multiUploadViewController.date]]) {
                    [newImages addObject:object];
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
            _multiUploadViewController.indexForCache = 0;
            _multiUploadViewController.tmpCacheCount = 0;
            
            _multiUploadViewController.imageLoadComplete = NO;
            [self setCacheOfParseImage:[[NSMutableArray alloc] initWithArray:newImages]];
        } else {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in getting Image Data from Parse : %@", error]];
        }
    }];
    
    // 不要なdirの削除
    [self removePastCandidateDir];
}

- (void)compensateBestImageId:(NSArray *)childImages
{}

-(void)setCacheOfParseImage:(NSMutableArray *)objects
{
    if ([objects count] > 0) {
        PFObject *object = [objects objectAtIndex:0];
        
        if ([object[@"isTmpData"] isEqualToString:@"TRUE"]) {
            // 本画像がはまるまではtmpを付けておく
            [ImageCache
                setCache:[NSString stringWithFormat:@"%@-tmp", object.objectId]
                image:UIImagePNGRepresentation([UIImage imageNamed:@"OnePx"])
                dir:[NSString stringWithFormat:@"%@/candidate/%@/thumbnail", _multiUploadViewController.childObjectId, _multiUploadViewController.date]
            ];
            _multiUploadViewController.tmpCacheCount++;
            
            _multiUploadViewController.indexForCache++;
            [objects removeObjectAtIndex:0];
            [self setCacheOfParseImage:objects];
        } else {
            AWSS3GetObjectRequest *getRequest = [AWSS3GetObjectRequest new];
            getRequest.bucket = [Config config][@"AWSBucketName"];
            getRequest.key = [NSString stringWithFormat:@"%@/%@", [NSString stringWithFormat:@"ChildImage%ld", (long)[_multiUploadViewController.child[@"childImageShardIndex"] integerValue]], object.objectId];
            AWSS3 *awsS3 = [[AWSS3 new] initWithConfiguration:_multiUploadViewController.configuration];
            [[awsS3 getObject:getRequest] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
                if (!task.error && task.result) {
                    AWSS3GetObjectOutput *getResult = (AWSS3GetObjectOutput *)task.result;
                    UIImage *thumbImage = [ImageCache makeThumbNail:[UIImage imageWithData:getResult.body]];
                    [ImageCache
                        setCache:object.objectId
                        image:UIImageJPEGRepresentation(thumbImage, 0.7f)
                        dir:[NSString stringWithFormat:@"%@/candidate/%@/thumbnail", _multiUploadViewController.childObjectId, _multiUploadViewController.date]
                    ];
                    [ImageCache removeCache:[NSString stringWithFormat:@"%@/candidate/%@/thumbnail/%@-tmp", _multiUploadViewController.childObjectId, _multiUploadViewController.date, object.objectId]];
                    [ImageCache
                        setCache:object.objectId
                        image:getResult.body
                        dir:[NSString stringWithFormat:@"%@/candidate/%@/fullsize", _multiUploadViewController.childObjectId, _multiUploadViewController.date]
                    ];
                    
                    _multiUploadViewController.indexForCache++;
                    [objects removeObjectAtIndex:0];
                    [self setCacheOfParseImage:objects];
                } else {
                    [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in getRequest to S3 : %@", task.error]];
                }
                return nil;
            }];
        }
    } else {
        _multiUploadViewController.imageLoadComplete = YES;
        [self showCacheImages];
        
        if (_multiUploadViewController.tmpCacheCount == 0){
            _multiUploadViewController.needTimer = NO;
            [_multiUploadViewController.myTimer invalidate];
        }
        
        [_multiUploadViewController.hud hide:YES];
        
        _multiUploadViewController.isTimperExecuting = NO;
    }
}

- (void)updateBestShot
{
    // update Parse
    PFQuery *childImageQuery = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%ld", (long)[_multiUploadViewController.child[@"childImageShardIndex"] integerValue]]];
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
                NSMutableDictionary *options = [[NSMutableDictionary alloc]init];
                options[@"formatArgs"] = [PFUser currentUser][@"nickName"];
                options[@"data"] = [[NSMutableDictionary alloc]initWithObjects:@[@"Increment"] forKeys:@[@"badge"]];
                [PushNotification sendInBackground:@"bestShotChosen" withOptions:options];
                [self createNotificationHistory:@"bestShotChanged"];
            }
            
        } else {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in get images : %@", error]];
        }
    }];

}

- (void)updateBestShotWithChild:(NSMutableDictionary *)childProperty withDate:(NSString *)date
{
    PFQuery *childImageQuery = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%ld", [childProperty[@"childImageShardIndex"] integerValue]]];
    childImageQuery.cachePolicy = kPFCachePolicyNetworkOnly;
    [childImageQuery whereKey:@"imageOf" equalTo:childProperty[@"objectId"]];
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
        NSLog(@"bestShotIndex %d", bestShotIndex);
        for (int i = 0; i < objects.count; i++) {
            PFObject *childImage = objects[i];
            childImage[@"bestFlag"] = (i == bestShotIndex) ? @"choosed" : @"unchoosed";
            [childImage saveInBackground];
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
    NSArray *targetTypes = [NSArray arrayWithObjects:@"imageUploaded", @"bestShotChanged", @"bestShotReply", nil];
    
    for (NSString *type in targetTypes) {
        if (_multiUploadViewController.notificationHistoryByDay && _multiUploadViewController.notificationHistoryByDay[type]) {
            for (PFObject *notificationHistory in _multiUploadViewController.notificationHistoryByDay[type]) {
                [NotificationHistory disableDisplayedNotificationsWithObject:notificationHistory];
            }
            [_multiUploadViewController.notificationHistoryByDay[type] removeAllObjects];
        }
    }
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

- (void)removeGestureForTutorial:(UICollectionViewCell *)cell
{}

- (void)finalizeProcess
{}

@end