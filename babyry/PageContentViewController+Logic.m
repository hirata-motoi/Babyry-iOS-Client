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
#import "AWSS3Utils.h"
#import "Config.h"
#import "AppSetting.h"
#import "NotificationHistory.h"
#import "ParseUtils.h"
#import "ImageRequestIntroductionView.h"
#import "ChildProperties.h"
#import "FamilyRole.h"
#import "PushNotification.h"

@implementation PageContentViewController_Logic {
    int iterateCount;
}

-(void)setImages
{
    [self showChildImages];
    [self setupImagesCount];
    [self updateChildProperties];
}

- (void)showChildImages
{
    iterateCount = 2;
    
    // 今月
    NSDateComponents *comp = [self dateComps];
    [self getChildImagesWithYear:comp.year withMonth:comp.month withReload:YES iterateCount:YES];
   
    // 先月
    NSDateComponents *lastComp = [self dateComps];
    lastComp.month--;
    [self getChildImagesWithYear:lastComp.year withMonth:lastComp.month withReload:YES iterateCount:YES];
  
    self.pageContentViewController.dateComp = lastComp;
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

- (void)getChildImagesWithYear:(NSInteger)year withMonth:(NSInteger)month withReload:(BOOL)reload iterateCount:(BOOL)iteration
{
    self.pageContentViewController.isLoading = YES;
    NSMutableDictionary *child = [ChildProperties getChildProperty:self.pageContentViewController.childObjectId];
    PFQuery *query = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%ld", (long)[child[@"childImageShardIndex"] integerValue]]];
    query.limit = 1000;
    [query whereKey:@"imageOf" equalTo:self.pageContentViewController.childObjectId];
    [query whereKey:@"date" greaterThanOrEqualTo:[NSNumber numberWithInteger:[[NSString stringWithFormat:@"%ld%02ld%02d", (long)year, (long)month, 1] integerValue]]];
    [query whereKey:@"date" lessThanOrEqualTo:[NSNumber numberWithInteger:[[NSString stringWithFormat:@"%ld%02ld%02d", (long)year, (long)month, 31] integerValue]]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if (!error) {
            NSNumber *indexNumber = [self.pageContentViewController.childImagesIndexMap objectForKey:[NSString stringWithFormat:@"%ld%02ld", (long)year, (long)month]];
            if (!indexNumber) {
                // 先月の画像が無い状態。この場合でも完了フラグはたてる
                if (iteration) {
                    iterateCount--;
                }
                [self.pageContentViewController.hud hide:YES];
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
                    for (PFObject *childImageDate in childImageDic[date]) {
                        if ([childImageDate[@"bestFlag"] isEqualToString:@"choosed"]) {
                            [images replaceObjectAtIndex:i withObject:childImageDate];
                            // ParseのupdatedAtが新しい時だけ
                            NSString *thumbPath = [NSString stringWithFormat:@"%@/bestShot/thumbnail/%@", self.pageContentViewController.childObjectId, [date stringValue]];
                            if ([childImageDate.updatedAt timeIntervalSinceDate:[ImageCache returnTimestamp:thumbPath]] > 0) {
                                
                                NSMutableDictionary *queueForCache = [[NSMutableDictionary alloc]init];
                                queueForCache[@"objectId"] = childImageDate.objectId;
                                queueForCache[@"date"] = childImageDate[@"date"];
                                if ([self isToday:index withRow:i]) {
                                    queueForCache[@"imageType"] = @"fullsize";
                                }
                                
                                [cacheSetQueueArray addObject:queueForCache];
                            }
                            bestshotExist = YES;
                        }
                    }
                    
                    NSIndexPath *ip = [NSIndexPath indexPathForRow:i inSection:index];
                    if ([self withinTwoDay:ip]) {
                        // 昨日、今日の場合は単に写真の枚数を突っ込む
                        [totalImageNum replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:[childImageDic[date] count]]];
                        // BestShotがない場合はcache削除(BestShotを削除した場合のため)
                        if (!bestshotExist) {
                            [ImageCache removeCache:[NSString stringWithFormat:@"%@/bestShot/thumbnail/%@", self.pageContentViewController.childObjectId, [date stringValue]]];
                            [ImageCache removeCache:[NSString stringWithFormat:@"%@/bestShot/fullsize/%@", self.pageContentViewController.childObjectId, [date stringValue]]];
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
                    [ImageCache removeCache:[NSString stringWithFormat:@"%@/bestShot/fullsize/%@", self.pageContentViewController.childObjectId, [date stringValue]]]; // fullsize
                }
            }
            [self setImageCache:cacheSetQueueArray withReload:reload];
            
            self.pageContentViewController.isLoading = NO;
           
            [self.pageContentViewController.hud hide:YES];
            [self showIntroductionOfImageRequest];
            self.pageContentViewController.isFirstLoad = 0;
            [self finalizeProcess];

        } else {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in getChildImagesWithYear : %@", error]];
            [self.pageContentViewController.hud hide:YES];
            [self.pageContentViewController showAlertMessage];
        }
        if (iteration) {
            iterateCount--;
        }
        if (iterateCount < 1 || !iteration) {
            [self setupNotificationHistory];
        }
    }];
    // 不要なfullsizeのキャッシュを消す
    [self removeUnnecessaryFullsizeCache];
}

- (BOOL)isToday:(NSInteger)section withRow:(NSInteger)row
{
    return (section == 0 && row == 0) ? YES : NO;
}

- (BOOL)withinTwoDay: (NSIndexPath *)indexPath
{
    PFObject *chilImage = [[[self.pageContentViewController.childImages objectAtIndex:indexPath.section] objectForKey:@"images"] objectAtIndex:indexPath.row];
    NSString *ymd = [chilImage[@"date"] stringValue];
    NSDateComponents *compToday = [self dateComps];
  
    NSDateFormatter *inputDateFormatter = [[NSDateFormatter alloc] init];
	[inputDateFormatter setDateFormat:@"yyyyMMdd"];
	NSDate *dateToday = [DateUtils setSystemTimezone: [inputDateFormatter dateFromString:[NSString stringWithFormat:@"%ld%02ld%02ld", (long)compToday.year, (long)compToday.month, (long)compToday.day]]];
	NSDate *dateTappedImage = [DateUtils setSystemTimezone: [inputDateFormatter dateFromString:ymd]];
 
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *diff = [cal components:NSDayCalendarUnit fromDate:dateTappedImage toDate:dateToday options:0];
    
    return [diff day] < 2;
}

- (void)setImageCache:(NSMutableArray *)cacheSetQueueArray withReload:(BOOL)reload
{
    NSMutableDictionary *childProperty = [ChildProperties getChildProperty:self.pageContentViewController.childObjectId];
    // 並列実行数
    int concurrency = 3;
    
    if ([cacheSetQueueArray count] > 0) {
        for (int i = 0; i < concurrency; i++) {
            // キャッシュ取り出し
            if ([cacheSetQueueArray count] > 0) {
                NSMutableDictionary *queue = [cacheSetQueueArray objectAtIndex:0];
                [cacheSetQueueArray removeObjectAtIndex:0];
                
                NSString *ymd = [queue[@"date"] stringValue];
                
                AWSS3GetObjectRequest *getRequest = [AWSS3GetObjectRequest new];
                getRequest.bucket = [Config config][@"AWSBucketName"];

                getRequest.key = [NSString stringWithFormat:@"%@/%@", [NSString stringWithFormat:@"ChildImage%ld", (long)[childProperty[@"childImageShardIndex"] integerValue]], queue[@"objectId"]];
                // no-cache必須
                getRequest.responseCacheControl = @"no-cache";
                AWSS3 *awsS3 = [[AWSS3 new] initWithConfiguration:self.pageContentViewController.configuration];
                
                [[awsS3 getObject:getRequest] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
                    
                    if (!task.error && task.result) {
                        AWSS3GetObjectOutput *getResult = (AWSS3GetObjectOutput *)task.result;
                       
                        if ([queue[@"imageType"] isEqualToString:@"fullsize"]) {
                            // fullsizeのimageをcache
                            [ImageCache
                                setCache:ymd
                                image:getResult.body
                                dir:[NSString stringWithFormat:@"%@/bestShot/fullsize", self.pageContentViewController.childObjectId]
                            ];
                        }
                        // ChileImageオブジェクトのupdatedAtとtimestampを比較するためthumbnailは常に作る
                        UIImage *thumbImage = [ImageCache makeThumbNail:[UIImage imageWithData:getResult.body]];
                        NSData *thumbData = [[NSData alloc] initWithData:UIImageJPEGRepresentation(thumbImage, 0.7f)];
                        [ImageCache setCache:ymd image:thumbData dir:[NSString stringWithFormat:@"%@/bestShot/thumbnail", self.pageContentViewController.childObjectId]];
                    } else {
                        [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in getRequsetOfS3 in setImageCache : %@", task.error]];
                    }
                    
                    if (reload) {
                        [self.pageContentViewController.pageContentCollectionView reloadData];
                        [NSThread sleepForTimeInterval:0.1];
                    }
                    if (i == concurrency - 1) {
                        [self setImageCache:cacheSetQueueArray withReload:reload];
                    }
                    return nil;
                }];
            }
        }
    } else {
        if (reload) {
            [self.pageContentViewController.pageContentCollectionView reloadData];
        }
    }
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
    [NSTimer scheduledTimerWithTimeInterval:2.0f target:self.pageContentViewController selector:@selector(addIntroductionOfImageRequestView:) userInfo:nil repeats:NO];
}

- (void)showIntroductionOfPageFlick:(NSMutableArray *)childProperties
{
    // 初回のみ
    AppSetting *appSetting = [AppSetting MR_findFirstByAttribute:@"name" withValue:[Config config][@"FinishedIntroductionOfPageFlick"]];
    if (appSetting || childProperties.count < 2 ) {
        return;
    }
    AppSetting *newAppSetting = [AppSetting MR_createEntity];
    newAppSetting.name = [Config config][@"FinishedIntroductionOfPageFlick"];
    newAppSetting.value = @"";
    newAppSetting.createdAt = [DateUtils setSystemTimezone:[NSDate date]];
    newAppSetting.updatedAt = [DateUtils setSystemTimezone:[NSDate date]];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    [NSTimer scheduledTimerWithTimeInterval:2.0f target:self.pageContentViewController selector:@selector(addIntroductionOfPageFlickView:) userInfo:nil repeats:NO];
}

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
    // TODO 誕生日以前のデータは無視する
    // ChildImage.dateの型をNumberにしたら対応する
    NSString *className = [NSString stringWithFormat:@"ChildImage%ld", (long)[childProperty[@"childImageShardIndex"] integerValue]];
    PFQuery *query = [PFQuery queryWithClassName:className];
    [query whereKey:@"imageOf" equalTo:self.pageContentViewController.childObjectId];
    [query whereKey:@"bestFlag" equalTo:@"choosed"];
    
    [query countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        if (!error) {
            [self.pageContentViewController.imagesCountDic setObject:[NSNumber numberWithInt:number] forKey:@"imagesCountNumber"];
        } else {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in setupImagesCount : %@", error]];
        }
    }];
}

- (void)setupNotificationHistory
{
    self.pageContentViewController.notificationHistory = [[NSMutableDictionary alloc]init];
    [NotificationHistory getNotificationHistoryInBackground:[PFUser currentUser][@"userId"] withType:nil withChild:self.pageContentViewController.childObjectId withBlock:^(NSMutableDictionary *history){
        // ポインタを渡しておいて、そこに情報をセットさせる
        // ただし、imageUpload or bestShotChoosen or commentPosted のpush通知をもらった場合はnotificationHistoryを更新しない(自動で開くので)
        NSDictionary *info = [TransitionByPushNotification getInfo];
        if (![info[@"event"] isEqualToString:@"imageUpload"] && ![info[@"event"] isEqualToString:@"bestShotChoosen"] && ![info[@"event"] isEqualToString:@"commentPosted"]) {
            for (NSString *ymd in history) {
                [self.pageContentViewController.notificationHistory setObject: [NSDictionary dictionaryWithDictionary:[history objectForKey:ymd]] forKey:ymd];
            }
            [self.pageContentViewController.pageContentCollectionView reloadData];
        }
        [self.pageContentViewController dispatchForPushReceivedTransition];
        [self.pageContentViewController.pageContentCollectionView reloadData];
        [self disableRedundantNotificationHistory];
        [self removeUnnecessaryGMPBadge];
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
    return [self withinTwoDay:indexPath];
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

- (void)setupHeaderView
{
    [self hideFamilyApplyIntroduceView];
}

- (void)hideFamilyApplyIntroduceView
{
    PageContentViewController *vc = self.pageContentViewController;
    if (!vc.familyApplyIntroduceView) {
        return;
    }
    
    // パートナー申請誘導viewの分collection viewを大きくする
    CGRect rect = vc.familyApplyIntroduceView.frame;
    CGRect collectionRect = vc.pageContentCollectionView.frame;
    collectionRect.size.height = collectionRect.size.height + rect.size.height;
    collectionRect.origin.y = collectionRect.origin.y - rect.size.height;
    vc.pageContentCollectionView.frame = collectionRect;
    
    [vc.familyApplyIntroduceView removeFromSuperview];
    vc.familyApplyIntroduceView = nil;
}

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
            [self.pageContentViewController.pageContentCollectionView reloadData];
        } else {
            [self showIntroductionOfPageFlick:(NSMutableArray *)childProperties];
        }
    }];
}

// notification historyの過去のバグで、notificationがつく → 画像を消す とすると
// notificationがついたままになってしまうので、
// notificationがあるけども画像がない -> notificationをdisableする
- (void)disableRedundantNotificationHistory
{
    NSMutableArray *targetYMDs = [[NSMutableArray alloc]init];
    for (NSString *ymd in [self.pageContentViewController.notificationHistory allKeys]) {
        [targetYMDs addObject:[NSNumber numberWithInteger:[ymd integerValue]]];
    }
    
    // choosedの写真がない日を探す
    NSMutableDictionary *childProperty = [ChildProperties getChildProperty:self.pageContentViewController.childObjectId];
    PFQuery *query = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%ld", (long)[childProperty[@"childImageShardIndex"] integerValue]]];
    [query whereKey:@"imageOf" equalTo:childProperty[@"objectId"]];
    [query whereKey:@"bestFlag" equalTo:@"choosed"];
    [query whereKey:@"date" containedIn:targetYMDs];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Failed to get choosed images for disableRedundantNotificationHistory Error:%@", error]];
            return;
        }
        
        NSMutableDictionary *choosedYMD = [[NSMutableDictionary alloc]init];
        for (PFObject *childImage in objects) {
            choosedYMD[ [childImage[@"date"] stringValue] ] = [NSNumber numberWithBool:YES];
        }
        
        BOOL shouldReload = NO;
        for (NSString *ymd in [self.pageContentViewController.notificationHistory allKeys]) {
            if (choosedYMD[ymd]) {
                continue;
            }
            // 今日・昨日に関してはchoosedが一枚もない場合が普通にあるので判別不可能なので
            // PageContentViewController内で、写真が一枚もない場合はnotificationを見せない対応をする
            NSIndexPath *ip = [self indexPathFromYMD:ymd];
            if (!ip || [self withinTwoDay:ip]) {
                continue;
            }
            
            // choosedの画像がないにも関わらずnotificationが残っている日のnotificationはdisable
            [self disableNotificationHistory:ymd];
            shouldReload = YES;
        }
        if (shouldReload) {
            [self.pageContentViewController.pageContentCollectionView reloadData];
        }
    }];
}

// 1. uploaderの時に受け取っていたgive me photoはchooserに切り替わったら要らないので消す
// 2. 2日以上前の場合はgive me photoのアイコンは要らないので消す
- (void)removeUnnecessaryGMPBadge
{
    for (NSMutableDictionary *notification in [self.pageContentViewController.notificationHistory allValues]) {
        for (NSString *type in [notification allKeys]) {
            if ([type isEqualToString:@"requestPhoto"]) {
                for (PFObject *object in notification[type]){
                    if ([[FamilyRole selfRole:@"useCache"] isEqualToString:@"chooser"]) {
                        [NotificationHistory disableDisplayedNotificationsWithObject:object];
                    } else {
                        if (!([object[@"date"] isEqualToNumber:[DateUtils getTodayYMD]] || [object[@"date"] isEqualToNumber:[DateUtils getYesterdayYMD]])) {
                            [NotificationHistory disableDisplayedNotificationsWithObject:object];
                        }
                    }
                }
            }
        }
    }
}

// childPropertiesのあらゆる要素が更新された場合にPageContentViewを書き直す必要はない(全部で書き直すと画像を上げたらTopに戻ってしまったり、パートナーが誕生日を更新したらTopに戻ってしまったり、が起きる)
// PageViewControllerの作り直しが必要なのは以下
//    1. こどもの数が変わったとき
//    2. こどものidが一致しない時
// 以下のケースではPageContentViewControllerをreloadする
//    1. 名前
//    2. calendarStartDate
//    3. 誕生日
//    4. 最古の写真の日付
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
        if (                                
            [self nameChanged:currentChild withBeforeChild:beforeChild]                 ||
            [self calendarStartDateChanged:currentChild withBeforeChild:beforeChild]    ||
            [self birthdayChanged:currentChild withBeforeChild:beforeChild]             ||
            [self oldestChildImageDateChanged:currentChild withBeforeChild:beforeChild]
        ) {
            reloadType = @"reloadPageContentViewDate";
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
                     
- (BOOL)birthdayChanged:(NSMutableDictionary *)currentChild withBeforeChild:(NSMutableDictionary *)beforeChild
{
    NSDate *currentDate = currentChild[@"birthday"];
    NSDate *beforeDate  = beforeChild[@"birthday"];
    
    if (!currentDate && !beforeDate) {
        return NO;
    }
    
    if ( !(currentDate && beforeDate) ) {
        return YES;
    }
    
    if (![currentDate isEqualToDate:beforeDate]) {
        return YES;
    }
    
    return NO;
}
                       
- (BOOL)oldestChildImageDateChanged:(NSMutableDictionary *)currentChild withBeforeChild:(NSMutableDictionary *)beforeChild
{
    NSNumber *currentDate = currentChild[@"oldestChildImageDate"];
    NSNumber *beforeDate  = beforeChild[@"oldestChildImageDate"];
    
    if (!currentDate && !beforeDate) {
        return NO;
    }
    
    if ( !(currentDate && beforeDate) ) {
        return YES;
    }
    
    if (![currentDate isEqualToNumber:beforeDate]) {
        return YES;
    }
    
    return NO;
}
                                   
- (BOOL)nameChanged:(NSMutableDictionary *)currentChild withBeforeChild:(NSMutableDictionary *)beforeChild
{
    if (![currentChild[@"name"] isEqualToString:beforeChild[@"name"]]) {
        return YES;
    }
    return NO;
}
                                                                        
- (BOOL)calendarStartDateChanged:(NSMutableDictionary *)currentChild withBeforeChild:(NSMutableDictionary *)beforeChild
{
    NSNumber *currentStartDate = currentChild[@"calendarStartDate"];
    NSNumber *beforeStartDate  = beforeChild[@"calendarStartDate"];
    
    if (!currentStartDate && !beforeStartDate) {
        return NO;
    }
    
    if ( !(currentStartDate && beforeStartDate) ) {
        return YES;
    }

    if (![currentStartDate isEqualToNumber:beforeStartDate]) {
        return YES;
    }
    
    return NO;
}

- (BOOL)isEqualDictionary:(NSDictionary *)child1 withCompare:(NSDictionary *)child2
{
    // createdByはPFUser objectのポインタが入っている
    // Parseから取得する度に別のポインタをとるので異なるobjectと判定されるためここでは無視する
    NSMutableDictionary *dic1 = [[NSMutableDictionary alloc]initWithDictionary:child1];
    [dic1 removeObjectForKey:@"createdBy"];
    NSMutableDictionary *dic2 = [[NSMutableDictionary alloc]initWithDictionary:child2];
    [dic2 removeObjectForKey:@"createdBy"];
    
    return [dic1 isEqualToDictionary:dic2];
}

- (NSDateComponents *)compsToAdd:(NSNumber *)oldestChildImageDate
{
    NSDateComponents *comps = [DateUtils compsFromNumber:oldestChildImageDate];
    if (comps.day == 1) {
        // 月初であれば前の月
        NSDateComponents *preMonthComps = [DateUtils addDateComps:comps withUnit:@"month" withValue:-1];
        return preMonthComps;
    } else {
        // 月初でなければその月
        comps.day = 1;
        return comps;
    }
}

- (void)addMonthToCalendar:(NSIndexPath *)indexPath
{
    if (![self canAddCalendar:indexPath.section]) {
        return;
    }
    
    PFObject *oldestChildImage = self.pageContentViewController.childImages[indexPath.section][@"images"][indexPath.row - 1];
    NSNumber *date = oldestChildImage[@"date"];
    NSDateComponents *compsToAdd = [self compsToAdd:date];
  
    [self.pageContentViewController showLoadingIcon];
    
    // Child.calendarStartDateを保存
    PFQuery *query = [PFQuery queryWithClassName:@"Child"];
    [query whereKey:@"objectId" equalTo:self.pageContentViewController.childObjectId];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Failed to get Child for saving calendarStartDate Child.objectId:%@", self.pageContentViewController.childObjectId]];
            // TODO ネットワークを確かめてalertを表示
            [self.pageContentViewController hideLoadingIcon];
            return;
        }
        
        if (objects.count == 0) {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Cannot find Child for saving calendarStartDate Child.objectId:%@", self.pageContentViewController.childObjectId]];
            [self.pageContentViewController hideLoadingIcon];
            return;
        }
        
        if (objects.count > 0) {
            NSString *ymd = [NSString stringWithFormat:@"%ld%02ld%02ld", (long)compsToAdd.year, (long)compsToAdd.month, (long)compsToAdd.day];
            NSNumber *calendarStartDate = [NSNumber numberWithInteger:[ymd integerValue]];
            PFObject *child = objects[0];
            child[@"calendarStartDate"] = calendarStartDate;
            [child saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (error) {
                    [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Failed to save Child.calendarStartDate Child.objectId:%@ calendarStartDate:%@", self.pageContentViewController.childObjectId, calendarStartDate]];
                    // TODO ネットワークを確かめてalertを表示
                    [self.pageContentViewController hideLoadingIcon];
                    return;
                }
                // CoreDataに保存
                [ChildProperties updateChildPropertyWithObjectId:self.pageContentViewController.childObjectId withParams:[NSMutableDictionary dictionaryWithObjects:@[calendarStartDate] forKeys:@[@"calendarStartDate"]]];
                
                // _childImagesにPFObjectを追加
                [self addEmptyChildImages:compsToAdd];
                // PageContentViewControllerをreload
                [self.pageContentViewController.pageContentCollectionView reloadData];
                
                [self.pageContentViewController hideLoadingIcon];
                
                [self sendPushNotificationForCalendarAdded];
            }];
        }
    }];
}

// compsToAddまでのchildImageを追加する
- (void)addEmptyChildImages:(NSDateComponents *)compsToAdd
{
    NSMutableDictionary *childProperty = [ChildProperties getChildProperty:self.pageContentViewController.childObjectId];
    NSMutableArray *childImages = self.pageContentViewController.childImages;
    NSMutableDictionary *oldestSection = childImages[childImages.count - 1];
    
    NSInteger oldestSectionYear  = [oldestSection[@"year"] integerValue];
    NSInteger oldestSectionMonth = [oldestSection[@"month"] integerValue];
   
    NSMutableArray *images;
    NSMutableDictionary *section;
    if (oldestSectionYear == compsToAdd.year && oldestSectionMonth == compsToAdd.month) {
        // 最初のカレンダー追加時はその月の月初までを追加する
        images = oldestSection[@"images"];
        section = oldestSection;
        
    } else {
        // 一ヶ月分のカレンダーを追加
        section = [[NSMutableDictionary alloc]init];
        images = [[NSMutableArray alloc]init];
        section[@"images"] = images;
        section[@"totalImageNum"] = [[NSMutableArray alloc]init];
        section[@"weekdays"]      = [[NSMutableArray alloc]init];
        section[@"year"]          = [NSString stringWithFormat:@"%ld", (long)compsToAdd.year];
        section[@"month"]         = [NSString stringWithFormat:@"%02ld", (long)compsToAdd.month];
        [childImages addObject:section];
    }
    
    PFObject *oldestChildImage = oldestSection[@"images"][ [oldestSection[@"images"] count] - 1 ];
    NSString *oldestChildImageDate = oldestChildImage[@"date"];
    NSDateComponents *oldestComps = [DateUtils compsFromNumber:[NSNumber numberWithInteger:[oldestChildImageDate integerValue]]];
  
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *dateToAdd = [DateUtils setSystemTimezone:[cal dateFromComponents:compsToAdd]];
    NSDate *oldestDateToAdd = [DateUtils setSystemTimezone:[cal dateFromComponents:oldestComps]];
    
    int i = 0; // safty
    while ([oldestDateToAdd compare:dateToAdd] == NSOrderedDescending) {
        oldestComps = [DateUtils addDateComps:oldestComps withUnit:@"day" withValue:-1];
        oldestDateToAdd = [cal dateFromComponents:oldestComps];
        
        PFObject *childImage = [[PFObject alloc]initWithClassName:[NSString stringWithFormat:@"ChildImage%ld", (long)[childProperty[@"childImageShardIndex"] integerValue]]];
        childImage[@"date"] = [NSNumber numberWithInteger:[[NSString stringWithFormat:@"%ld%02ld%02ld", (long)oldestComps.year, (long)oldestComps.month, (long)oldestComps.day] integerValue]];
        [images addObject:childImage];
        [section[@"totalImageNum"] addObject:[NSNumber numberWithInt:-1]];
        [section[@"weekdays"] addObject: [NSNumber numberWithInteger:oldestComps.weekday]];
        
        i++;
        if (i >= 31) {
            break;
        }
    }
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

- (void)disableNotificationHistory:(NSString *)ymd
{
    for (NSString *type in [self.pageContentViewController.notificationHistory[ymd] allKeys]) {
        NSArray *notificationHistories = self.pageContentViewController.notificationHistory[ymd][type];
        for (PFObject *notificationHistory in notificationHistories) {
            [NotificationHistory disableDisplayedNotificationsWithObject:notificationHistory];
        }
        [self.pageContentViewController.notificationHistory[ymd][type] removeAllObjects];
    }
}

// 2009年分のカレンダーまでは追加可能とする
// こどもの誕生日の下限が2010/01/01なので、決めでその一年前とする
- (BOOL)canAddCalendar:(NSInteger)section
{
    NSInteger year = [self.pageContentViewController.childImages[section][@"year"] integerValue];
    NSInteger month = [self.pageContentViewController.childImages[section][@"month"] integerValue];
    return !(year < 2009 || (year == 2009 && month == 1));
    
}

// silent push
- (void)sendPushNotificationForCalendarAdded
{
    NSMutableDictionary *transitionInfoDic = [[NSMutableDictionary alloc] init];
    transitionInfoDic[@"event"] = @"calendarAdded";
    NSMutableDictionary *options = [[NSMutableDictionary alloc]init];
    options[@"data"] = [[NSMutableDictionary alloc]
                        initWithObjects:@[@"Increment", transitionInfoDic, [NSNumber numberWithInt:1]]
                        forKeys:@[@"badge", @"transitionInfo", @"content-available"]];
    [PushNotification sendInBackground:@"calendarAdded" withOptions:options];
}

@end
