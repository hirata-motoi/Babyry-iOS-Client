//
//  TransitionByPushNotification.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/10/01.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "TransitionByPushNotification.h"
#import "MultiUploadViewController.h"
#import "ViewController.h"
#import "PageViewController.h"
#import "PageContentViewController.h"
#import "UploadViewController.h"
#import "FamilyRole.h"
#import "ImagePageViewController.h"
#import "UINavigationController+Block.h"
#import "MultiUploadViewController.h"
#import "DateUtils.h"
#import "UploadViewController.h"
#import "ImageCache.h"
#import "ChildProperties.h"
#import "Logger.h"
#import "NotificationHistory.h"

static NSMutableDictionary *transitionInfo;
static NSMutableDictionary *currentViewControllerInfo;
static BOOL appLaunchFlag = NO;

@implementation TransitionByPushNotification

+ (void) initialize
{
    transitionInfo = [[NSMutableDictionary alloc] init];
    currentViewControllerInfo = [[NSMutableDictionary alloc] init];
}

+ (void) setInfo:(NSMutableDictionary *)info
{
    transitionInfo = [[NSMutableDictionary alloc] initWithDictionary:info];
}

+ (NSDictionary *) getInfo
{
    return [[NSDictionary alloc] initWithDictionary:transitionInfo];
}

+ (void) removeInfo
{
    transitionInfo = [[NSMutableDictionary alloc] init];
}

+ (void) setAppLaunchedFlag
{
    appLaunchFlag = YES;
}

+ (void) removeAppLaunchFlag
{
    appLaunchFlag = NO;
}

+ (BOOL) checkAppLaunchedFlag
{
    return appLaunchFlag;
}

+ (void) setCurrentViewController:(NSString *)viewController
{
    currentViewControllerInfo[@"viewController"] = viewController;
}

+ (NSString *) getCurrentViewController
{
    if (currentViewControllerInfo[@"viewController"]) {
        return currentViewControllerInfo[@"viewController"];
    } else {
        return @"ViewController";
    }
}

+ (void) setCurrentPageIndex:(int)index
{
    currentViewControllerInfo[@"currentPageIndex"] = [NSNumber numberWithInt:index];
}

+ (int) getCurrentPageIndex
{
    if (currentViewControllerInfo[@"currentPageIndex"]) {
        return [currentViewControllerInfo[@"currentPageIndex"] intValue];
    } else {
        return 0;
    }
}

+ (void) setCurrentDate:(NSString *)date
{
    currentViewControllerInfo[@"currentDate"] = date;
}

+ (NSString *) getCurrentDate
{
    if (currentViewControllerInfo[@"currentDate"]) {
        return currentViewControllerInfo[@"currentDate"];
    } else {
        return @"";
    }
}

+ (BOOL) isCommentViewOpen
{
    if (currentViewControllerInfo[@"commentViewOpen"] && [currentViewControllerInfo[@"commentViewOpen"] isEqualToString:@"YES"]) {
        return YES;
    } else {
        return NO;
    }
}

+ (void) setCommentViewOpenFlag:(BOOL)openFlag
{
    if (openFlag) {
        currentViewControllerInfo[@"commentViewOpen"] = @"YES";
    } else {
        currentViewControllerInfo[@"commentViewOpen"] = @"NO";
    }
}

+ (BOOL)isReturnedToTop
{
    if (transitionInfo[@"returnedTop"] && [transitionInfo[@"returnedTop"] isEqualToString:@"YES"]) {
        return YES;
    } else {
        return NO;
    }
}

+ (void)returnToTop:(UIViewController *)vc
{
    if ([transitionInfo[@"event"] isEqualToString:@"receiveApply"] || [transitionInfo[@"event"] isEqualToString:@"admitApply"]) {
        [self executeReturnToTop:vc];
        return;
    }
    
    // notificationHistory消す
    [self removeNotificationHistoryForPushTransition:transitionInfo[@"event"]];
    
    // パートナーが操作したこどもとIdが一致していなければTopに戻る
    NSArray *childProperties = [ChildProperties getChildProperties];
    int index = 0;
    for (NSDictionary *childProperty in childProperties) {
        if ([childProperty[@"objectId"] isEqualToString:transitionInfo[@"childObjectId"]]) {
            break;
        }
        index++;
    }
    if ([self getCurrentPageIndex] == index) {
        // コメントだけは、一旦Topに戻らない。やり取りを始めると何度も Push->開く を繰り返すと思われるのでチカチカしないように。&コメントを自動遷移で開くのは結構大変(時間かかる)。
        if (![transitionInfo[@"event"] isEqualToString:@"commentPosted"]) {
            [self executeReturnToTop:vc];
            return;
        }
        if (![transitionInfo[@"date"] isEqualToString:[self getCurrentDate]]) {
            [self executeReturnToTop:vc];
            return;
        }
        if (![self isCommentViewOpen]){
            [self executeReturnToTop:vc];
            return;
        }
        [self removeInfo];
    } else {
        // childPropertiesChangedじゃないけど、ページ移動のために呼ぶ
        [self setCurrentPageIndex:index];
        NSNotification *n = [NSNotification notificationWithName:@"childPropertiesChanged" object:nil];
        [[NSNotificationCenter defaultCenter] postNotification:n];
        [self executeReturnToTop:vc];
    }
}

+ (void)executeReturnToTop:(UIViewController *)vc
{
    // TopにいなければTopに戻る
    [vc.navigationController setNavigationBarHidden:NO];
    transitionInfo[@"returnedTop"] = @"YES";
    if ([[vc.navigationController viewControllers] count] == 1) {
        [self dispatch:vc];
    } else {
        [vc.navigationController popToRootViewControllerAnimated:YES];
    }
}

+ (void)dispatch:(UIViewController *)vc
{
    // 方針
    // すべてのフローを一致させる(各パターンにあわせた複雑なフローは抜け漏れが発生してしまう)
    // 1. Topに戻る
    // 2. こどもを切り替える
    // 3. 当該日付のMulti or Upload Viewを開く
    // 4. コメントの場合は、コメントのViewまで開く
    // 以上を高速に行う事が出来れば、必要ない場合でもTopに戻る時のオーバーヘッドは考えなくても良い
    // ※ 例外は上に書いてあるけどCommentViewだけ (使ってみてチカチカ遷移がうざかったら他のやつも変える)

    if ([transitionInfo[@"event"] isEqualToString:@"imageUpload"] || [transitionInfo[@"event"] isEqualToString:@"bestShotChosen"]) {
        if ([DateUtils isInTwodayByIndexPath:[NSIndexPath indexPathForRow:[transitionInfo[@"row"] intValue] inSection:[transitionInfo[@"section"] intValue]]]) {
            [self moveToMultiUploadViewControllerForPushTransition:vc];
        } else {
            [self moveToImagePageViewControllerForPushTransition:vc];
        }
    } else if ([transitionInfo[@"event"] isEqualToString:@"commentPosted"]) {
        [self moveToUploadViewControllerWithCommentForPushTransition:vc];
    } else {
        [self removeInfo];
    }
}

+ (void)removeNotificationHistoryForPushTransition:(NSString *)type
{
    // pushで遷移してくると、メモリ上(notificationHistory)には保存されていないものの、Parse上にはパートナーが入れたデータがあるのでそれを削除する
    // transitionInfoとnotificationHistoryで使われるkeyの名前が一致していないのでここで吸収する
    // notificationHistoryのkeyは、requestPhoto, imageUploaded, commentPosted, bestShotChanged
    NSMutableArray *notificationTypeArray = [[NSMutableArray alloc] init];
    if ([transitionInfo[@"event"] isEqualToString:@"imageUpload"]) {
        [notificationTypeArray addObject:@"imageUploaded"];
    } else if ([transitionInfo[@"event"] isEqualToString:@"bestShotChosen"]) {
        // ベストショットが変わった時は、multiUploadを開く => imageUploadedのプッシュも消す必要あり
        [notificationTypeArray addObject:@"bestShotChanged"];
        [notificationTypeArray addObject:@"imageUploaded"];
    } else if ([transitionInfo[@"event"] isEqualToString:@"commentPosted"]) {
        // コメント開く => upされた画像を見る事になる
        [notificationTypeArray addObject:@"commentPosted"];
        [notificationTypeArray addObject:@"imageUploaded"];
    }
    if ([notificationTypeArray count] < 1) {
        return;
    }
    for (NSString *type in notificationTypeArray) {
        [NotificationHistory getNotificationHistoryObjectsByDateInBackground:[PFUser currentUser][@"userId"] withType:type withChild:transitionInfo[@"childObjectId"] date:[NSNumber numberWithInt:[transitionInfo[@"date"] intValue]] withBlock:^(NSArray *objects){
            
            int i = 0;
            for (PFObject *object in objects) {
                i++;
               
                if (i >= objects.count) {
                    [NotificationHistory disableDisplayedNotificationsWithObject:object withBlock:^(void){
                        NSNotification *n = [NSNotification notificationWithName:@"resetImage" object:nil];
                        [[NSNotificationCenter defaultCenter] postNotification:n];
                    }];
                } else {
                    [NotificationHistory disableDisplayedNotificationsWithObject:object];
                }
            }
        }];
    }
}

+ (void) moveToMultiUploadViewControllerForPushTransition:(UIViewController *)vc
{
    MultiUploadViewController *multiUploadViewController = [vc.storyboard instantiateViewControllerWithIdentifier:@"MultiUploadViewController"];
    multiUploadViewController.childObjectId = transitionInfo[@"childObjectId"];
    multiUploadViewController.date = transitionInfo[@"date"];
    multiUploadViewController.month = [transitionInfo[@"date"] substringWithRange:NSMakeRange(0, 6)];
    multiUploadViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    multiUploadViewController.indexPath = [NSIndexPath indexPathForRow:[transitionInfo[@"row"] intValue] inSection:[transitionInfo[@"section"] intValue]];
    
    [vc.navigationController pushViewController:multiUploadViewController animated:YES onCompletion:^(void){
        [self removeInfo];
    }];
}

+ (void) moveToImagePageViewControllerForPushTransition:(UIViewController *)vc
{
    ImagePageViewController *pageViewController = [vc.storyboard instantiateViewControllerWithIdentifier:@"ImagePageViewController"];
    pageViewController.showPageNavigation = NO; // PageContentViewControllerから表示する場合、全部で何枚あるかが可変なので出さない
    pageViewController.childObjectId = transitionInfo[@"childObjectId"];
    [vc.navigationController setNavigationBarHidden:YES];
    [vc.navigationController pushViewController:pageViewController animated:YES onCompletion:^(void){
        [self removeInfo];
    }];
}

+ (void) moveToUploadViewControllerWithCommentForPushTransition:(UIViewController *)vc
{
    UploadViewController *uploadViewController = [vc.storyboard instantiateViewControllerWithIdentifier:@"UploadViewController"];
    uploadViewController.childObjectId = transitionInfo[@"childObjectId"];

    NSString *ymd = transitionInfo[@"date"];
    NSString *year  = [ymd substringWithRange:NSMakeRange(0, 4)];
    NSString *month = [ymd substringWithRange:NSMakeRange(4, 2)];

    uploadViewController.month = [NSString stringWithFormat:@"%@%@", year, month];
    uploadViewController.date = ymd;
    uploadViewController.indexPath = [NSIndexPath indexPathForRow:[transitionInfo[@"row"] intValue] inSection:[transitionInfo[@"section"] intValue]];
    
    NSString *cacheDir = [NSString stringWithFormat:@"%@/bestShot/thumbnail", transitionInfo[@"childObjectId"]];
    
    NSData *imageCacheData = [ImageCache getCache:ymd dir:cacheDir];
    
    if (imageCacheData) {
        uploadViewController.uploadedImage = [UIImage imageWithData:imageCacheData];
    }
    uploadViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [vc.navigationController setNavigationBarHidden:YES];
    [vc.navigationController pushViewController:uploadViewController animated:YES onCompletion:^(void){
        [self removeInfo];
    }];
}

@end
