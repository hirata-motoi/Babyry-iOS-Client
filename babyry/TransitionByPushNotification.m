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

static NSMutableDictionary *transitionInfo;
static NSMutableDictionary *currentViewController;
static NSMutableDictionary *returnDic;

@implementation TransitionByPushNotification

+ (void) initialize
{
    transitionInfo = [[NSMutableDictionary alloc] init];
    currentViewController = [[NSMutableDictionary alloc] init];
    returnDic = [[NSMutableDictionary alloc] init];
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

+ (void) setCurrentViewController:(NSString *)viewController
{
    currentViewController[@"viewController"] = viewController;
}

+ (NSString *) getCurrentViewController
{
    if (currentViewController[@"viewController"]) {
        return currentViewController[@"viewController"];
    } else {
        return @"ViewController";
    }
}

+ (void) setCurrentPageIndex:(int)index
{
    currentViewController[@"currentPageIndex"] = [NSNumber numberWithInt:index];
}

+ (int) getCurrentPageIndex
{
    if (currentViewController[@"currentPageIndex"]) {
        return [currentViewController[@"currentPageIndex"] intValue];
    } else {
        return 0;
    }
}

+ (void) setCurrentDate:(NSString *)ymd
{
    currentViewController[@"currentDate"] = ymd;
}

+ (NSString *)getCurrentDate
{
    if (currentViewController[@"currentDate"]) {
        return currentViewController[@"currentDate"];
    } else {
        return nil;
    }
}

+ (NSMutableDictionary *) dispatch:(UIViewController *)viewController childObjectId:(NSString *)currentChildObjectId selectedDate:(NSString *)currentDate
{
    NSLog(@"currentViewControllerがとれない場合には何もしない");
    // currentViewControllerがとれない場合には何もしない
    if (!currentViewController[@"viewController"]) {
        return nil;
    }

    NSLog(@"transitionInfoがとれない or eventが空の場合は何もしない");
    // transitionInfoがとれない or eventが空の場合は何もしない
    if (!transitionInfo || [transitionInfo[@"event"] isEqualToString:@""]) {
        // transisionInfoが無ければそのままretrun
        return nil;
    }
    
    NSLog(@"インスタントに使う用にreturnDicとして深いコピー");
    // インスタントに使う用にreturnDicとして深いコピー
    returnDic = [[NSMutableDictionary alloc] initWithDictionary:transitionInfo];
    
    NSLog(@"起動一発目は値が入らない かつ 一発目は必ずtopのViewControllerが入るので");
    // 起動一発目は値が入らない かつ 一発目は必ずtopのViewControllerが入るので
    if (!currentViewController[@"viewController"]) {
        currentViewController[@"viewController"] = @"ViewController";
    }
    NSLog(@"currentViewController %@", currentViewController[@"viewController"]);
    
    NSLog(@"transitionInfo %@", transitionInfo);
    
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
    
    NSLog(@"returnDicA %@", returnDic);
    return returnDic;
}

+ (NSMutableDictionary *)dispatchForImageOperation:(UIViewController *)viewController childObjectId:(NSString *)currentChildObjectId selectedDate:(NSString *)currentDate
{
    NSLog(@"dispatchForImageOperation");
    if ([currentViewController[@"viewController"] isEqualToString:@"ViewController"]) {
        NSLog(@"currentview is ViewController");
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
        NSLog(@"returnDicB %@", returnDic);
        return returnDic;
    } else if ([currentViewController[@"viewController"] isEqualToString:@"MultiUploadViewController"]) {
        NSLog(@"currentview is MultiUploadViewController");
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
                NSLog(@"returnDicC %@", returnDic);
                return returnDic;
            }
        }
        [self returnToRoot:viewController];
        return nil;
    } else if ([currentViewController[@"viewController"] isEqualToString:@"ImagePageViewController"]) {
        NSLog(@"currentview is ImagePageViewController %@, %@", [TransitionByPushNotification getCurrentDate], currentChildObjectId);
        NSLog(@"transition %@", transitionInfo);
        if ([[TransitionByPushNotification getCurrentDate] isEqualToString:transitionInfo[@"date"]] && [currentChildObjectId isEqualToString:transitionInfo[@"childObjectId"]]) {
            NSLog(@"日付、こども一致");
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
        NSLog(@"一致しない");
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
    NSLog(@"returnToRoot");
    [viewController.navigationController setNavigationBarHidden:NO];
    [viewController.navigationController popToRootViewControllerAnimated:YES];
//
//        NSNotification *n = [NSNotification notificationWithName:@"childPropertiesChanged" object:nil];
//        [[NSNotificationCenter defaultCenter] postNotification:n];
}

@end
