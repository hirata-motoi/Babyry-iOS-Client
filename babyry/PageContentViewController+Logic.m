//
//  PageContentViewController+Logic.m
//  babyry
//
//  Created by hirata.motoi on 2014/09/16.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "PageContentViewController+Logic.h"
#import "ArrayUtils.h"
#import "ImageCache.h"
#import "Logger.h"
#import "DateUtils.h"
#import "AWSCommon.h"
#import "Config.h"
#import "AppSetting.h"
#import "NotificationHistory.h"
#import "ParseUtils.h"
//#import "ImageRequestIntroductionView.h"
#import "ChildProperties.h"
#import "FamilyRole.h"
#import "PushNotification.h"
#import "AWSS3Utils.h"
#import "ChildIconManager.h"
#import "Comment.h"

@implementation PageContentViewController_Logic

-(void)setImages
{
    [self showChildImages];
    [self setupImagesCount];
    [self updateChildProperties];
    [Comment updateCommentNumEntity];
    [self removeUnnecessaryGMPBadge];
}

- (void)showChildImages
{
    // 今画面に表示されている月を取得
    NSArray* visibleCellIndex = self.pageContentViewController.pageContentCollectionView.indexPathsForVisibleItems;
    NSMutableDictionary *visibleDateDic = [[NSMutableDictionary alloc] init];
    for (NSIndexPath *ip in visibleCellIndex) {
        NSString *yyyymm = [NSString stringWithFormat:@"%@%@", self.pageContentViewController.childImages[ip.section][@"year"], self.pageContentViewController.childImages[ip.section][@"month"]];
        if (!visibleDateDic[yyyymm]) {
            NSDateComponents *currentDateComp = [self dateComps];
            currentDateComp.year = [self.pageContentViewController.childImages[ip.section][@"year"] intValue];
            currentDateComp.month = [self.pageContentViewController.childImages[ip.section][@"month"] intValue];
            visibleDateDic[yyyymm] = currentDateComp;
        }
    }
    if ([visibleCellIndex count] == 0) {
        NSDateComponents *thisMonthComps = [DateUtils dateCompsFromDate:nil];
        NSDateComponents *lastMonthComps = [DateUtils addDateComps:thisMonthComps withUnit:@"month" withValue:-1];
        visibleDateDic[[NSString stringWithFormat:@"%04d%02d", thisMonthComps.year, thisMonthComps.month]] = thisMonthComps;
        visibleDateDic[[NSString stringWithFormat:@"%04d%02d", lastMonthComps.year, lastMonthComps.month]] = lastMonthComps;
    }
    
    for (NSString *yyyymm in visibleDateDic) {
        NSDateComponents *comp = visibleDateDic[yyyymm];
        [self getChildImagesWithYear:comp.year withMonth:comp.month withReload:YES];
        
        // dateComp(スクロールで読み込み済みの日付)が空ならそのまま突っ込む
        // 空じゃないなら、dateCompに比べて日付が古いときだけ突っ込む
        if (!self.pageContentViewController.dateComp) {
            self.pageContentViewController.dateComp = comp;
        } else {
            NSCalendar *cal = [NSCalendar currentCalendar];
            NSDate *visibleDate = [cal dateFromComponents:comp];
            NSDate *loadedDate = [cal dateFromComponents:self.pageContentViewController.dateComp];
            if ([visibleDate compare:loadedDate] == NSOrderedAscending) {
                self.pageContentViewController.dateComp = comp;
            }
        }
    }
}

- (NSDateComponents *)dateComps
{
    NSDate *date = [NSDate date];
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *dateComps = [cal components:
        NSYearCalendarUnit   |
        NSMonthCalendarUnit  |
        NSDayCalendarUnit    |
        NSHourCalendarUnit   |
        NSWeekdayCalendarUnit
    fromDate:date];
    return dateComps;
}

- (void)getChildImagesWithYear:(NSInteger)year withMonth:(NSInteger)month withReload:(BOOL)reload
{
    self.pageContentViewController.isLoading = YES;
    NSMutableDictionary *child = [ChildProperties getChildProperty:self.pageContentViewController.childObjectId];
    PFQuery *query = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%ld", (long)[child[@"childImageShardIndex"] integerValue]]];
    query.limit = 1000;
    [query whereKey:@"imageOf" equalTo:self.pageContentViewController.childObjectId];
    [query whereKey:@"date" greaterThanOrEqualTo:[NSNumber numberWithInteger:[[NSString stringWithFormat:@"%ld%02ld%02d", (long)year, (long)month, 1] integerValue]]];
    [query whereKey:@"date" lessThanOrEqualTo:[NSNumber numberWithInteger:[[NSString stringWithFormat:@"%ld%02ld%02d", (long)year, (long)month, 31] integerValue]]];
	[query whereKey:@"bestFlag" notEqualTo:@"removed"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        // 上まで引っ張った時に出てくるクルクルを消す
        // クルクルしている時にendRefreshingを呼び出しても無害っぽいので基本的に読んでおく(isRunnning的なフラグを立てるほどでもない)
        // getChildImagesWithYearの対象が2つあるときもあり得るが、そこはあんまり気にしてない(2つをほぼ同時に呼ぶのでそれほど時間差はないはず)
        [self.pageContentViewController.rc endRefreshing];
        if (!error) {
            NSNumber *indexNumber = [self.pageContentViewController.childImagesIndexMap objectForKey:[NSString stringWithFormat:@"%ld%02ld", (long)year, (long)month]];
            if (!indexNumber) {
                [self.pageContentViewController.hud hide:YES];
                self.pageContentViewController.isLoading = NO;
                return;
            }
            NSInteger index = [indexNumber integerValue];
            NSMutableDictionary *section = [self.pageContentViewController.childImages objectAtIndex:index];
            NSMutableArray *images = [section objectForKey:@"images"];
            NSMutableArray *totalImageNum = [section objectForKey:@"totalImageNum"];
            
            NSMutableDictionary *childImageDic = [ArrayUtils arrayToHash:objects withKeyColumn:@"date"];
            
            NSMutableArray *cacheSetQueueArray = [[NSMutableArray alloc] init];
            for (int i = 0; i < [images count]; i++) {
                PFObject *childImage = [images objectAtIndex:i];
                
                NSNumber *date = childImage[@"date"];

                if (childImageDic[date]) {
                    BOOL bestshotExist = NO;
					NSIndexPath *ip = [NSIndexPath indexPathForRow:i inSection:index];
                    for (PFObject *childImageDate in childImageDic[date]) {
                        if ([childImageDate[@"bestFlag"] isEqualToString:@"choosed"]) {
                            [images replaceObjectAtIndex:i withObject:childImageDate];
                            // ParseのupdatedAtが新しい時だけ
                            NSString *thumbPath = [NSString stringWithFormat:@"%@/bestShot/thumbnail/%@", self.pageContentViewController.childObjectId, [date stringValue]];
                            if ([childImageDate.updatedAt timeIntervalSinceDate:[ImageCache returnTimestamp:thumbPath]] > 0) {
                                
                                NSMutableDictionary *queueForCache = [[NSMutableDictionary alloc]init];
                                queueForCache[@"objectId"] = childImageDate.objectId;
								queueForCache[@"childObjectId"] = self.pageContentViewController.childObjectId;
                                queueForCache[@"date"] = childImageDate[@"date"];
                                queueForCache[@"isBS"] = [NSNumber numberWithBool:YES];
                                if ([DateUtils isTodayByIndexPath:ip]) {
                                    queueForCache[@"isFullSize"] = [NSNumber numberWithBool:YES];
                                }
                                
                                [cacheSetQueueArray addObject:queueForCache];
                            }
                            bestshotExist = YES;
							
                            if ([DateUtils isInTwodayByIndexPath:ip]) {
								self.pageContentViewController.bestImageIds[[date stringValue]] = childImageDate.objectId;
							}
                        }
						if ([DateUtils isInTwodayByIndexPath:ip]) {
							NSString *thumbPath = [NSString stringWithFormat:@"%@/candidate/%@/thumbnail/%@", self.pageContentViewController.childObjectId, [date stringValue], childImageDate.objectId];
                            if ([childImageDate.updatedAt timeIntervalSinceDate:[ImageCache returnTimestamp:thumbPath]] > 0) {
                                
                                NSMutableDictionary *queueForCache = [[NSMutableDictionary alloc]init];
                                queueForCache[@"objectId"] = childImageDate.objectId;
								queueForCache[@"childObjectId"] = self.pageContentViewController.childObjectId;
                                queueForCache[@"date"] = childImageDate[@"date"];
								queueForCache[@"isCandidate"] = [NSNumber numberWithBool:YES];
                                
                                [cacheSetQueueArray addObject:queueForCache];
                            }
						}
                    }
                    if ([DateUtils isInTwodayByIndexPath:ip]) {
                        // 昨日、今日の場合は単に写真の枚数を突っ込む
                        [totalImageNum replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:[childImageDic[date] count]]];
                        // BestShotがない場合はcache削除(BestShotを削除した場合のため)
                        if (!bestshotExist) {
                            [ImageCache removeCache:[NSString stringWithFormat:@"%@/bestShot/thumbnail/%@", self.pageContentViewController.childObjectId, [date stringValue]]];
                            [ImageCache removeCache:[NSString stringWithFormat:@"%@/bestShot/fullsize/%@", self.pageContentViewController.childObjectId, [date stringValue]]];
                        }
                        // 昨日、今日の場合、Parse上では消されたがキャッシュには残っている画像があるのでそれを消す
                        // パートナーが削除したパターン
                        NSArray *allCaches = [ImageCache getListOfMultiUploadCache:[NSString stringWithFormat:@"%@/candidate/%@/thumbnail", self.pageContentViewController.childObjectId, [date stringValue]]];
                        for (NSString *cacheId in allCaches) {
                            BOOL removeCache = YES;
                            for (PFObject *childImageDate in childImageDic[date]) {
                                if ([cacheId isEqualToString:childImageDate.objectId]) {
                                    removeCache = NO;
                                    break;
                                }
                            }
                            if (removeCache) {
                                [ImageCache removeCache:[NSString stringWithFormat:@"%@/candidate/%@/thumbnail/%@", self.pageContentViewController.childObjectId, [date stringValue], cacheId]];
                                [ImageCache removeCache:[NSString stringWithFormat:@"%@/candidate/%@/fullsize/%@", self.pageContentViewController.childObjectId, [date stringValue], cacheId]];
                            }
                        }
                    } else {
                        // 二日以上前で、ベストショットが無いのであれば、0を入れてキャッシュ消す
                        if(!bestshotExist) {
                            [totalImageNum replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:0]];
                            // 本画像がないのでローカルにキャッシュがあれば消す。
                            [ImageCache removeCache:[NSString stringWithFormat:@"%@/bestShot/thumbnail/%@", self.pageContentViewController.childObjectId, [date stringValue]]];
                        } else {
                            [totalImageNum replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:1]];
                        }
                    }
                } else {
                    [totalImageNum replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:0]];
                    // 本画像がないのでローカルにキャッシュがあれば消す。
                    [ImageCache removeCache:[NSString stringWithFormat:@"%@/bestShot/thumbnail/%@", self.pageContentViewController.childObjectId, [date stringValue]]];
                    [ImageCache removeCache:[NSString stringWithFormat:@"%@/bestShot/fullsize/%@", self.pageContentViewController.childObjectId, [date stringValue]]];
                    // candidateも消す
                    NSArray *allCaches = [ImageCache getListOfMultiUploadCache:[NSString stringWithFormat:@"%@/candidate/%@/thumbnail", self.pageContentViewController.childObjectId, [date stringValue]]];
                    for (NSString *cacheId in allCaches) {
                        [ImageCache removeCache:[NSString stringWithFormat:@"%@/candidate/%@/thumbnail/%@", self.pageContentViewController.childObjectId, [date stringValue], cacheId]];
                        [ImageCache removeCache:[NSString stringWithFormat:@"%@/candidate/%@/fullsize/%@", self.pageContentViewController.childObjectId, [date stringValue], cacheId]];
                    }
                }
            }
			AWSS3Utils *awsS3Utils = [[AWSS3Utils alloc] init];
			[awsS3Utils makeCacheFromS3:cacheSetQueueArray configuration:self.pageContentViewController.configuration withBlock:^(void){
				[self executeReload];
			}];
            
            self.pageContentViewController.isLoading = NO;
           
            [self.pageContentViewController.hud hide:YES];
            [self showIntroductionOfImageRequest];
            self.pageContentViewController.isFirstLoad = 0;
            [self finalizeProcess];
        } else {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in getChildImagesWithYear : %@", error]];
            [self.pageContentViewController.hud hide:YES];
            [self.pageContentViewController showAlertMessage];
            self.pageContentViewController.isLoading = NO;
        }
    }];
    // 不要なfullsizeのキャッシュを消す
    [self removeUnnecessaryFullsizeCache];
}

- (void)compensateDateOfChildImage:(NSArray *)objects
{}

- (void)compensateBestFlagOfChildImage:(NSArray *)objects
{}

- (void)showIntroductionOfImageRequest
{
    if ([self.pageContentViewController.selfRole isEqualToString:@"uploader"]) {
        return;
    }

    // チョイスとしての初load以外ならreturn
    AppSetting *appSetting = [AppSetting MR_findFirstByAttribute:@"name" withValue:[Config config][@"FinishedFirstLaunch"]];
    if (appSetting) {
        return;
    }
    
    AppSetting *newAppSetting = [AppSetting MR_createEntity];
    newAppSetting.name = [Config config][@"FinishedFirstLaunch"];
    newAppSetting.value = @"";
    newAppSetting.createdAt = [DateUtils setSystemTimezone:[NSDate date]];
    newAppSetting.updatedAt = [DateUtils setSystemTimezone:[NSDate date]];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    //[NSTimer scheduledTimerWithTimeInterval:2.0f target:self.pageContentViewController selector:@selector(addIntroductionOfImageRequestView:) userInfo:nil repeats:NO];
}

//- (void)showIntroductionOfPageFlick:(NSMutableArray *)childProperties
//{
//    // 初回のみ
//    AppSetting *appSetting = [AppSetting MR_findFirstByAttribute:@"name" withValue:[Config config][@"FinishedIntroductionOfPageFlick"]];
//    if (appSetting || childProperties.count < 2 ) {
//        return;
//    }
//    AppSetting *newAppSetting = [AppSetting MR_createEntity];
//    newAppSetting.name = [Config config][@"FinishedIntroductionOfPageFlick"];
//    newAppSetting.value = @"";
//    newAppSetting.createdAt = [DateUtils setSystemTimezone:[NSDate date]];
//    newAppSetting.updatedAt = [DateUtils setSystemTimezone:[NSDate date]];
//    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
//    [NSTimer scheduledTimerWithTimeInterval:2.0f target:self.pageContentViewController selector:@selector(addIntroductionOfPageFlickView:) userInfo:nil repeats:NO];
//}

- (void)removeUnnecessaryFullsizeCache
{
    NSDateComponents *todayComps = [self dateComps];
    NSString *ymd = [NSString stringWithFormat:@"%ld%02ld%02ld", todayComps.year, todayComps.month, todayComps.day];
   
    NSArray *cacheFiles = [ImageCache listCachedImage:[NSString stringWithFormat:@"ImageCache/%@/bestShot/fullsize", self.pageContentViewController.childObjectId]];
    for (NSString *fileName in cacheFiles) {
        if ([fileName isEqualToString:ymd]) {
            continue;
        }
        [ImageCache removeCache:[NSString stringWithFormat:@"%@/%@/%@", self.pageContentViewController.childObjectId, @"bestShot/fullsize", fileName]];
    }
}

- (void)setupImagesCount
{
    NSMutableDictionary *childProperty = [ChildProperties getChildProperty:self.pageContentViewController.childObjectId];
    NSString *className = [NSString stringWithFormat:@"ChildImage%ld", (long)[childProperty[@"childImageShardIndex"] integerValue]];
    PFQuery *query = [PFQuery queryWithClassName:className];
    [query whereKey:@"imageOf" equalTo:self.pageContentViewController.childObjectId];
    [query whereKey:@"bestFlag" equalTo:@"choosed"];
    // bestshot1000枚 = 2.7年 とりあえず大丈夫か
    query.limit = 1000;
    [query countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        if (!error) {
            [self.pageContentViewController.imagesCountDic setObject:[NSNumber numberWithInt:number] forKey:@"imagesCountNumber"];
        } else {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in setupImagesCount : %@", error]];
        }
    }];
}

- (void) showGlobalMenuBadge
{
    [NotificationHistory getNotificationHistoryInBackground:[PFUser currentUser][@"userId"] withType:nil withChild:nil withStatus:@"ready" withLimit:1000 withBlock:^(NSArray *objects){
        [self.pageContentViewController.delegate setGlobalMenuBadge:[objects count]];
    }];
}

- (NSDate *)getCollectionViewFirstDay
{
    NSMutableDictionary *childProperty = [ChildProperties getChildProperty:self.pageContentViewController.childObjectId];
    NSDate *birthday = childProperty[@"birthday"];
    NSDate *base = [DateUtils setSystemTimezone:[NSDate date]];
    if (!birthday || [base timeIntervalSinceDate:birthday] < 0) {
        birthday = childProperty[@"createdAt"] ? childProperty[@"createdAt"] : [NSDate date];
    }

    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *birthdayComps = [cal components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:birthday];
    NSDateComponents *firstDayComps = [DateUtils addDateComps:birthdayComps withUnit:@"month" withValue:-2];

    NSDate *firstDay = [cal dateFromComponents:firstDayComps];

    return firstDay;
}

- (NSMutableArray *)screenSavedChildImages
{
    NSMutableArray *savedChildImages = [[NSMutableArray alloc]init];
    for (NSMutableDictionary *section in self.pageContentViewController.childImages) {
        NSMutableDictionary *newSection = [[NSMutableDictionary alloc]init];
        newSection[@"year"] = section[@"year"];
        newSection[@"month"] = section[@"month"];
        newSection[@"images"] = [[NSMutableArray alloc]init];
        [savedChildImages addObject:newSection];
        
        for (PFObject *childImage in section[@"images"]) {
            // 実際にParse上に画像が保存されているPFObjectかどうかを
            // objectIdがあるかで判定
            if (childImage.objectId) {
                [newSection[@"images"] addObject:childImage];
            }
        }
    }
    return savedChildImages;
}

- (NSInteger)currentIndexRowInSavedChildImages:(NSIndexPath *)indexPath
{
    NSMutableArray *targetChildImageList = self.pageContentViewController.childImages[indexPath.section][@"images"];
    
    NSInteger indexInSavedChildImages = -1;
    for (NSInteger i = 0; i < targetChildImageList.count; i++) {
        PFObject *childImage = targetChildImageList[i];
        if (childImage.objectId) {
            indexInSavedChildImages++;
        }
        if (i == indexPath.row) {
            return indexInSavedChildImages;
        }
    }
    return 0;
}

// 今週
// 今週じゃない かつ 候補写真がある かつ 未choosed
- (BOOL)shouldShowMultiUploadView:(NSIndexPath *)indexPath
{
    // 2日間はMultiUploadViewController
    return [DateUtils isInTwodayByIndexPath:indexPath];
}

- (BOOL)isNoImage:(NSIndexPath *)indexPath
{
    NSMutableDictionary *section = [self.pageContentViewController.childImages objectAtIndex:indexPath.section];
    NSMutableArray *totalImageNum = [section objectForKey:@"totalImageNum"];
    
    if ([[totalImageNum objectAtIndex:indexPath.row] compare:[NSNumber numberWithInt:1]] == NSOrderedAscending) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)isBestImageFixed:(NSIndexPath *)indexPath
{
    NSMutableDictionary *section = [self.pageContentViewController.childImages objectAtIndex:indexPath.section];
    NSMutableArray *totalImageNum = [section objectForKey:@"totalImageNum"];
    
    if ([[totalImageNum objectAtIndex:indexPath.row] intValue] > 0) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)forbiddenSelectCell:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)finalizeProcess
{}

- (void)forwardNextTutorial
{}

- (void)updateChildProperties
{
    [ChildProperties asyncChildPropertiesWithBlock:^(NSArray *beforeSyncChildProperties) {
        NSMutableArray *childProperties = [ChildProperties getChildProperties];
        NSString *reloadType = [self getReloadTypeAfterChildPropertiesChanged:beforeSyncChildProperties withChildProperties:childProperties];
        
        if ([reloadType isEqualToString:@"replacePageView"]) {
            NSNotification *n = [NSNotification notificationWithName:@"childPropertiesChanged" object:nil];
            [[NSNotificationCenter defaultCenter] postNotification:n];
        } else if ([reloadType isEqualToString:@"reloadPageContentViewDate"]) {
            [self.pageContentViewController adjustChildImages];
            [self executeReload];
        } else if ([reloadType isEqualToString:@"reloadChildSwitchView"]) {
            [ChildIconManager syncChildIconsInBackground];
//        } else {
//            [self showIntroductionOfPageFlick:(NSMutableArray *)childProperties];
        }
    }];
}


// 1. uploaderの時に受け取っていたgive me photoはchooserに切り替わったら要らないので消す
// 2. 2日以上前の場合はgive me photoのアイコンは要らないので消す
- (void)removeUnnecessaryGMPBadge
{
    [NotificationHistory getNotificationHistoryLessThanTargetDateInBackground:[PFUser currentUser][@"userId"]
    withType:@"requestPhoto" withChild:self.pageContentViewController.childObjectId withStatus:nil withLimit:1000 withLimitDate:[DateUtils getYesterdayYMD] withBlock:^(NSArray *objects){
        for (PFObject *object in objects) {
            object[@"status"] = @"removed";
            [object saveEventually];
        }
    }];
}

// childPropertiesのあらゆる要素が更新された場合にPageContentViewを書き直す必要はない(全部で書き直すと画像を上げたらTopに戻ってしまったり、パートナーが誕生日を更新したらTopに戻ってしまったり、が起きる)
// PageViewControllerの作り直しが必要なのは以下
//    1. こどもの数が変わったとき
//    2. こどものidが一致しない時
// 以下のケースではPageContentViewControllerをreloadする
//    1. 名前
// 以下のケースではChildSwitchViewのアイコンリロードだけを行う
//    1. iconVersion
// Viewがいきなり変わるので、push通知で知らせた方が良いかもね(TODO)
- (NSString *)getReloadTypeAfterChildPropertiesChanged:(NSArray *)beforeSyncChildProperties withChildProperties:(NSMutableArray *)childProperties
{
    // こどもの数が変わったとき
    if ([self childAddedOrDeleted:childProperties withBeforeChildProperties:beforeSyncChildProperties]) {
        return @"replacePageView";
    }
    
    NSMutableDictionary *currentChildDic = [[NSMutableDictionary alloc] init];
    for (NSMutableDictionary *childProperty in childProperties) {
        currentChildDic[childProperty[@"objectId"]] = childProperty;
    }
    
    NSString *reloadType = @"noNeedToReload"; // default
    
    for (NSMutableDictionary *beforeChild in beforeSyncChildProperties) {
        if ([self childReplaced:currentChildDic withBeforeChild:beforeChild]) {
            return @"replacePageView";
        }
        
        NSString *objectId = beforeChild[@"objectId"];
        NSMutableDictionary *currentChild = currentChildDic[objectId];
        if ([self nameChanged:currentChild withBeforeChild:beforeChild]) {
            reloadType = @"reloadPageContentViewDate";
        }
       
        // iconVersionだけが変更になった場合。reloadPageContentViewDateの時にやる処理はアイコンのリロードを含むため
        if (
            [self iconVersionChanged:currentChild withBeforeChild:beforeChild] &&
            [reloadType isEqualToString:@"noNeedToReload"]
        ) {
            reloadType = @"reloadChildSwitchView";
        }
    }
    return reloadType;
}

- (BOOL)childAddedOrDeleted:(NSMutableArray *)childProperties withBeforeChildProperties:(NSArray *)beforeSyncChildProperties
{
    if (childProperties.count != beforeSyncChildProperties.count) {
        return YES;
    }
    return NO;
}

- (BOOL)childReplaced:(NSMutableDictionary *)currentChildDic withBeforeChild:(NSMutableDictionary *)beforeChild
{
    return currentChildDic[ beforeChild[@"objectId"] ] ? NO : YES;
}

- (BOOL)nameChanged:(NSMutableDictionary *)currentChild withBeforeChild:(NSMutableDictionary *)beforeChild
{
    if (![currentChild[@"name"] isEqualToString:beforeChild[@"name"]]) {
        return YES;
    }
    return NO;
}

- (BOOL)iconVersionChanged:(NSMutableDictionary *)currentChild withBeforeChild:(NSMutableDictionary *)beforeChild
{
    if (! [currentChild[@"iconVersion"] isEqualToNumber:beforeChild[@"iconVersion"]]) {
        return YES;
    }
    return NO;
}
                                                                        
- (NSIndexPath *)indexPathFromYMD:(NSString *)ymd
{
    NSNumber *ymdNumber = [NSNumber numberWithInteger:[ymd integerValue]];
    
    // index pathを取得
    NSInteger sectionIndex = [[self.pageContentViewController.childImagesIndexMap objectForKey:[ymd substringWithRange:NSMakeRange(0, 6)] ] integerValue];
    NSMutableDictionary *section = [self.pageContentViewController.childImages objectAtIndex:sectionIndex];
    NSMutableArray *images = [section objectForKey:@"images"];
    for (NSInteger i = 0; i < images.count; i++) {
        PFObject *childImage = images[i];
        if ([childImage[@"date"] isEqualToNumber:ymdNumber]) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:sectionIndex];
            return indexPath;
        }
    }
    return nil;
}


- (void)removeDialogs
{}

// cell回転中にreloadDataが呼ばれるとアニメーションが停止してしまうので
// 回転中はreloadDataを呼ばない
- (void)executeReload
{
    if (!self.pageContentViewController.isRotatingCells) {
        [self.pageContentViewController.pageContentCollectionView reloadData];
    } else {
        self.pageContentViewController.skippedReloadData = YES;
    }
}

@end
