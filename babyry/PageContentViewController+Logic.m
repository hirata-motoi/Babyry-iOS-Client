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

@implementation PageContentViewController_Logic

-(void)setImages
{
    [self showChildImages];
    [self setupImagesCount];
    [self setupNotificationHistory];
}

- (void)showChildImages
{
    // 今月
    NSDateComponents *comp = [self dateComps];
    [self getChildImagesWithYear:comp.year withMonth:comp.month withReload:YES];
   
    // 先月
    NSDateComponents *lastComp = [self dateComps];
    lastComp.month--;
    [self getChildImagesWithYear:lastComp.year withMonth:lastComp.month withReload:YES];
  
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
        NSHourCalendarUnit
    fromDate:date];
    return dateComps;
}

- (void)getChildImagesWithYear:(NSInteger)year withMonth:(NSInteger)month withReload:(BOOL)reload
{
    self.pageContentViewController.isLoading = YES;
    NSMutableDictionary *child = self.pageContentViewController.childProperty;
    PFQuery *query = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%ld", (long)[child[@"childImageShardIndex"] integerValue]]];
    query.limit = 1000;
    [query whereKey:@"imageOf" equalTo:self.pageContentViewController.childObjectId];
    
    if (year > 0 && month > 0) {
        [query whereKey:@"date" greaterThanOrEqualTo:[NSNumber numberWithInteger:[[NSString stringWithFormat:@"%ld%02ld%02d", (long)year, (long)month, 1] integerValue]]];
        [query whereKey:@"date" lessThanOrEqualTo:[NSNumber numberWithInteger:[[NSString stringWithFormat:@"%ld%02ld%02d", (long)year, (long)month, 31] integerValue]]];
    }
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if (!error) {
            
            [self compensateDateOfChildImage:objects];
            [self compensateBestFlagOfChildImage:objects];
            
            NSInteger index = [[self.pageContentViewController.childImagesIndexMap objectForKey:[NSString stringWithFormat:@"%ld%02ld", (long)year, (long)month]] integerValue];
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

                getRequest.key = [NSString stringWithFormat:@"%@/%@", [NSString stringWithFormat:@"ChildImage%ld", (long)[self.pageContentViewController.childProperty[@"childImageShardIndex"] integerValue]], queue[@"objectId"]];
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
    [NSTimer scheduledTimerWithTimeInterval:2.0f target:self.pageContentViewController selector:@selector(addIntrodutionOfImageRequestView:) userInfo:nil repeats:NO];
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
    // TODO 誕生日以前のデータは無視する
    // ChildImage.dateの型をNumberにしたら対応する
    NSMutableDictionary *child = self.pageContentViewController.childProperty;
    NSString *className = [NSString stringWithFormat:@"ChildImage%ld", (long)[child[@"childImageShardIndex"] integerValue]];
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
        for (NSString *ymd in history) {
            [self.pageContentViewController.notificationHistory setObject: [NSDictionary dictionaryWithDictionary:[history objectForKey:ymd]] forKey:ymd];
        }
        [self.pageContentViewController.pageContentCollectionView reloadData];
    }];
    
}

// 誕生日の2ヶ月前からcellを表示する
// birthdayがなかった場合はcreatedAtを誕生日とする
- (NSDate *)getCollectionViewFirstDay
{
    NSMutableDictionary *child = self.pageContentViewController.childProperty;
    NSDate *birthday = child[@"birthday"];
    NSDate *base = [DateUtils setSystemTimezone:[NSDate date]];
    if (!birthday || [base timeIntervalSinceDate:birthday] < 0) {
        birthday = child[@"createdAt"];
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
{}

@end
