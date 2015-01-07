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
#import "ImageRequestIntroductionView.h"
#import "ChildProperties.h"
#import "FamilyRole.h"
#import "PushNotification.h"
#import "AWSS3Utils.h"

@implementation PageContentViewController_Logic

-(void)setImages
{
    [self showChildImages];
    [self setupImagesCount];
    [self updateChildProperties];
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
        if (!error) {
            NSNumber *indexNumber = [self.pageContentViewController.childImagesIndexMap objectForKey:[NSString stringWithFormat:@"%ld%02ld", (long)year, (long)month]];
            if (!indexNumber) {
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
                                if ([self isToday:index withRow:i]) {
                                    queueForCache[@"imageType"] = @"fullsize";
                                }
                                
                                [cacheSetQueueArray addObject:queueForCache];
                            }
                            bestshotExist = YES;
							
							if ([self withinTwoDay:ip]) {
								self.pageContentViewController.bestImageIds[[date stringValue]] = childImageDate.objectId;
							}
                        }
						if ([self withinTwoDay:ip]) {
							NSString *thumbPath = [NSString stringWithFormat:@"%@/candidate/%@/thumbnail/%@", self.pageContentViewController.childObjectId, [date stringValue], childImageDate.objectId];
                            if ([childImageDate.updatedAt timeIntervalSinceDate:[ImageCache returnTimestamp:thumbPath]] > 0) {
                                
                                NSMutableDictionary *queueForCache = [[NSMutableDictionary alloc]init];
                                queueForCache[@"objectId"] = childImageDate.objectId;
								queueForCache[@"childObjectId"] = self.pageContentViewController.childObjectId;
                                queueForCache[@"date"] = childImageDate[@"date"];
								queueForCache[@"imageType"] = @"candidate";
                                
                                [cacheSetQueueArray addObject:queueForCache];
                            }
						}
                    }
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
    NSString *className = [NSString stringWithFormat:@"ChildImage%ld", (long)[childProperty[@"childImageShardIndex"] integerValue]];
    PFQuery *query = [PFQuery queryWithClassName:className];
    [query whereKey:@"imageOf" equalTo:self.pageContentViewController.childObjectId];
    [query whereKey:@"bestFlag" equalTo:@"choosed"];
    // imagesCountDicの用途的に15がmaxなので問題ないけど
    // 用途が増えて100以上になったらlimitを設定する必要あり、1000以上を超える場合にはそれを考慮した書き方に変更しないとだめ
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
        // ただし、imageUpload or bestShotChoosen or commentPosted のpush通知をもらった場合はnotificationHistoryを更新しない
        // Pushで開く時はnotificationHistoryを渡さないで即開くので
        NSDictionary *info = [TransitionByPushNotification getInfo];
        if (![info[@"event"] isEqualToString:@"imageUpload"] && ![info[@"event"] isEqualToString:@"bestShotChoosen"] && ![info[@"event"] isEqualToString:@"commentPosted"]) {
            for (NSString *ymd in history) {
                [self.pageContentViewController.notificationHistory setObject: [NSDictionary dictionaryWithDictionary:[history objectForKey:ymd]] forKey:ymd];
            }
            [self executeReload];
        }
            [self executeReload];
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
            [[NSNotificationCenter defaultCenter] postNotificationName:@"childSwitchViewIconChanged" object:nil];
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
            [self executeReload];
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
