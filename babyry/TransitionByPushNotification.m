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

static NSMutableDictionary *transitionInfo;
static NSMutableDictionary *currentViewControllerInfo;
//static NSMutableDictionary *returnDic;

@implementation TransitionByPushNotification

+ (void) initialize
{
    transitionInfo = [[NSMutableDictionary alloc] init];
    currentViewControllerInfo = [[NSMutableDictionary alloc] init];
//    returnDic = [[NSMutableDictionary alloc] init];
}

+ (void) setInfo:(NSMutableDictionary *)info
{
    NSLog(@"TransitionByPushNotification setInfo");
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

+ (void) setCurrentDate:(NSString *)ymd
{
    currentViewControllerInfo[@"currentDate"] = ymd;
}

+ (NSString *)getCurrentDate
{
    if (currentViewControllerInfo[@"currentDate"]) {
        return currentViewControllerInfo[@"currentDate"];
    } else {
        return nil;
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
        NSLog(@"setCommentViewOpenFlag YES");
        currentViewControllerInfo[@"commentViewOpen"] = @"YES";
    } else {
        NSLog(@"setCommentViewOpenFlag NO");
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
        NSLog(@"id一致");
        // コメントだけは、一旦Topに戻らない。やり取りを始めると何度も Push->開く を繰り返すと思われるのでチカチカしないように。&コメントを自動遷移で開くのは結構大変(時間かかる)。
        if (![transitionInfo[@"event"] isEqualToString:@"commentPosted"]) {
            NSLog(@"commentPostedじゃないよ！");
            [self executeReturnToTop:vc index:index];
            return;
        }
        if (![self isCommentViewOpen]){
            NSLog(@"CommentViewControllerじゃないよ！ %@", [self getCurrentViewController]);
            [self executeReturnToTop:vc index:index];
            return;
        }
        NSLog(@"id一致してコメントを開いているので何もしない");
        [self removeInfo];
    } else {
        NSLog(@"id不一致");
        // childPropertiesChangedじゃないけど、ページ移動のために呼ぶ
        [self setCurrentPageIndex:index];
        NSNotification *n = [NSNotification notificationWithName:@"childPropertiesChanged" object:nil];
        [[NSNotificationCenter defaultCenter] postNotification:n];
        [self executeReturnToTop:vc index:index];
    }
}

+ (void)executeReturnToTop:(UIViewController *)vc index:(int)index
{
    // TopにいなければTopに戻る
    [vc.navigationController setNavigationBarHidden:NO];
    transitionInfo[@"returnedTop"] = @"YES";
    if ([[vc.navigationController viewControllers] count] == 1) {
        [self dispatch2:vc];
    } else {
        [vc.navigationController popToRootViewControllerAnimated:YES];
    }
}

+ (void)dispatch2:(UIViewController *)vc
{
    NSLog(@"TransitionByPushNotification dispatch2 %@", transitionInfo);
    // 方針
    // すべてのフローを一致させる(各パターンにあわせた複雑なフローは抜け漏れが発生してしまう)
    // 1. Topに戻る
    // 2. こどもを切り替える
    // 3. 当該日付のMulti or Upload Viewを開く
    // 4. コメントの場合は、コメントのViewまで開く
    // 以上を高速に行う事が出来れば、必要ない場合でもTopに戻る時のオーバーヘッドは考えなくても良い

    if ([transitionInfo[@"event"] isEqualToString:@"imageUpload"]) {
        if ([DateUtils isInTwodayByIndexPath:[NSIndexPath indexPathForRow:[transitionInfo[@"row"] intValue] inSection:[transitionInfo[@"section"] intValue]]]) {
            [self moveToMultiUploadViewControllerForPushTransition:vc];
        } else {
            [self moveToImagePageViewControllerForPushTransition:vc];
        }
    } else if ([transitionInfo[@"event"] isEqualToString:@"commentPosted"]) {
        [self moveToUploadViewControllerWithCommentForPushTransition:vc];
    }
}

+ (void) moveToMultiUploadViewControllerForPushTransition:(UIViewController *)vc
{
    MultiUploadViewController *multiUploadViewController = [vc.storyboard instantiateViewControllerWithIdentifier:@"MultiUploadViewController"];
    multiUploadViewController.childObjectId = transitionInfo[@"childObjectId"];
    multiUploadViewController.date = transitionInfo[@"date"];
    multiUploadViewController.month = [transitionInfo[@"date"] substringWithRange:NSMakeRange(0, 6)];
    multiUploadViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    //multiUploadViewController.notificationHistoryByDay = _notificationHistory[[date substringWithRange:NSMakeRange(0, 8)]];
    multiUploadViewController.indexPath = [NSIndexPath indexPathForRow:[transitionInfo[@"row"] intValue] inSection:[transitionInfo[@"section"] intValue]];
    //multiUploadViewController.pCVC = self;
    
    [vc.navigationController pushViewController:multiUploadViewController animated:YES onCompletion:^(void){
        [self removeInfo];
    }];
}

+ (void) moveToImagePageViewControllerForPushTransition:(UIViewController *)vc
{
    ImagePageViewController *pageViewController = [vc.storyboard instantiateViewControllerWithIdentifier:@"ImagePageViewController"];
    pageViewController.showPageNavigation = NO; // PageContentViewControllerから表示する場合、全部で何枚あるかが可変なので出さない
    pageViewController.childObjectId = transitionInfo[@"childObjectId"];
    NSLog(@"aaaaaa %@", transitionInfo[@"childObjectId"]);
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
    NSString *imageCachePath = [[NSString alloc] init];
    NSString *cacheDir = [[NSString alloc]init];
    
    cacheDir = [NSString stringWithFormat:@"%@/bestShot/thumbnail", transitionInfo[@"childObjectId"]];
    imageCachePath = ymd;
    
    NSData *imageCacheData = [ImageCache getCache:imageCachePath dir:cacheDir];
    
    if (imageCacheData) {
        uploadViewController.uploadedImage = [UIImage imageWithData:imageCacheData];
    }
    uploadViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [vc.navigationController setNavigationBarHidden:YES];
    [vc.navigationController pushViewController:uploadViewController animated:YES onCompletion:^(void){
        [self removeInfo];
    }];
}


/*
+ (NSMutableDictionary *) dispatch:(UIViewController *)viewController childObjectId:(NSString *)currentChildObjectId selectedDate:(NSString *)currentDate
{
    // 何もしない
    return nil;
 
 
    // currentViewControllerがとれない場合には何もしない
    if (!currentViewController[@"viewController"]) {
        return nil;
    }

    // transitionInfoがとれない or eventが空の場合は何もしない
    if (!transitionInfo || [transitionInfo[@"event"] isEqualToString:@""]) {
        // transisionInfoが無ければそのままretrun
        return nil;
    }
    
    // インスタントに使う用にreturnDicとして深いコピー
    returnDic = [[NSMutableDictionary alloc] initWithDictionary:transitionInfo];
    
    // 起動一発目は値が入らない かつ 一発目は必ずtopのViewControllerが入るので
    if (!currentViewController[@"viewController"]) {
        currentViewController[@"viewController"] = @"ViewController";
    }
    
    if ([transitionInfo[@"event"] isEqualToString:@"imageUpload"]
        || [transitionInfo[@"event"] isEqualToString:@"commentPosted"]
        || [transitionInfo[@"event"] isEqualToString:@"bestShotChosen"]
        || [transitionInfo[@"event"] isEqualToString:@"requestPhoto"]) {
        returnDic = [self dispatchForImageOperation:viewController childObjectId:currentChildObjectId selectedDate:currentDate];
    }
    
    if ([transitionInfo[@"event"] isEqualToString:@"partSwitched"]){
        [FamilyRole getFamilyRole:@"NetworkFirst"];
        [self removeInfo];
        [self returnToRoot:viewController];
    }
    
    return returnDic;
}

+ (NSMutableDictionary *)dispatchForImageOperation:(UIViewController *)viewController childObjectId:(NSString *)currentChildObjectId selectedDate:(NSString *)currentDate
{
    if ([currentViewController[@"viewController"] isEqualToString:@"ViewController"]) {
        if ([transitionInfo[@"childObjectId"] isEqualToString:currentChildObjectId]) {
            if ([transitionInfo[@"event"] isEqualToString:@"imageUpload"]
                || [transitionInfo[@"event"] isEqualToString:@"bestShotChosen"]
                || [transitionInfo[@"event"] isEqualToString:@"commentPosted"]) {
                
                returnDic[@"nextVC"] = [self uploadType];
                
                // 画像アップロードの場合、遷移はこれで終わりなのでtransitionInfoを初期化
                if ([transitionInfo[@"event"] isEqualToString:@"imageUpload"]
                    || [transitionInfo[@"event"] isEqualToString:@"bestShotChosen"]) {
                    [self removeInfo];
                }
            } else if ([transitionInfo[@"event"] isEqualToString:@"requestPhoto"]) {
                [self removeInfo];
            }
        } else {
            returnDic[@"nextVC"] = @"movePageContentViewController";
        }
        return returnDic;
    } else if ([currentViewController[@"viewController"] isEqualToString:@"MultiUploadViewController"]) {
        if ([[TransitionByPushNotification getCurrentDate] isEqualToString:transitionInfo[@"date"]] && [currentChildObjectId isEqualToString:transitionInfo[@"childObjectId"]]) {
            if ([transitionInfo[@"event"] isEqualToString:@"imageUpload"] || [transitionInfo[@"event"] isEqualToString:@"bestShotChosen"]) {
                // ここでMultiUploadViewControllerのうまいreloadの仕方が思いつかない
                // notificationの方がまだましな気がしてきた
                MultiUploadViewController *vC = (MultiUploadViewController *)[viewController.navigationController topViewController];
                if (vC && [NSStringFromClass([vC class]) isEqualToString:@"MultiUploadViewController"]) {
                    [vC viewDidAppear:YES];
                }
                
                [self removeInfo];
                return nil;
            }
            
            if ([transitionInfo[@"event"] isEqualToString:@"commentPosted"]) {
                // 対象の日付、対象のこどものMultiUploadViewが開かれている状態
                // ベストショットがあればベストショット、決まってなければ最初の画像を開く
                returnDic[@"nextVC"] = @"CommentViewController";
                return returnDic;
            }
        }
        [self returnToRoot:viewController];
        return nil;
    } else if ([currentViewController[@"viewController"] isEqualToString:@"ImagePageViewController"]) {
        if ([[TransitionByPushNotification getCurrentDate] isEqualToString:transitionInfo[@"date"]] && [currentChildObjectId isEqualToString:transitionInfo[@"childObjectId"]]) {
            if ([transitionInfo[@"event"] isEqualToString:@"imageUpload"]) {
                // MultiUploadと同様
                // notificationの方がまだましな気がしてきた
                UploadViewController *vC = (UploadViewController *)[viewController.navigationController topViewController];
                if (vC && [NSStringFromClass([vC class]) isEqualToString:@"UploadViewController"]) {
                    [vC viewDidLoad];
                }
                
                [self removeInfo];
                return nil;
            } else if ([transitionInfo[@"event"] isEqualToString:@"commentPosted"]) {
                // 対象の日付、対象のこどものMultiUploadViewが開かれている状態
                // コメントを開くbabyry/AppDelegate.m
            }
        }
        [self returnToRoot:viewController];
        return nil;
    } else {
        [self returnToRoot:viewController];
        return nil;
    }
    
    return nil;
}

+ (NSString *)uploadType
{
    if ([transitionInfo[@"section"] isEqualToString:@"0"] && ([transitionInfo[@"row"] isEqualToString:@"0"] || [transitionInfo[@"row"] isEqualToString:@"1"])) {
        return @"MultiUploadViewController";
    } else {
        return @"UploadViewController";
    }
}

// ここの処理は毎回同じなので、受け取っているviewControllerで処理してしまう
+ (void) returnToRoot:(UIViewController *)viewController
{
    [viewController.navigationController setNavigationBarHidden:NO];
    [viewController.navigationController popToRootViewControllerAnimated:YES];
//
//        NSNotification *n = [NSNotification notificationWithName:@"childPropertiesChanged" object:nil];
//        [[NSNotificationCenter defaultCenter] postNotification:n];
}
 */

@end
