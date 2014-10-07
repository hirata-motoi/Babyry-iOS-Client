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

+ (void) endMoving
{
    if (transitionInfo) {
        transitionInfo[@"isMoving"] = [NSNumber numberWithBool:NO];
    }
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


+ (NSMutableDictionary *) dispatch:(UIViewController *)viewController childObjectId:(NSString *)currentChildObjectId selectedDate:(NSString *)currentDate
{
    NSLog(@"Load From %@", NSStringFromClass([viewController class]));
    NSLog(@"CurrentViewController %@", currentViewController[@"viewController"]);
    
    // 遷移中の場合は何もしない
    if ([transitionInfo[@"isMoving"] isEqualToNumber:[NSNumber numberWithBool:YES]]) {
        return nil;
    }
    
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
    
    if ([transitionInfo[@"event"] isEqualToString:@"imageUpload"] || [transitionInfo[@"event"] isEqualToString:@"commentPosted"] || [transitionInfo[@"event"] isEqualToString:@"bestShotChosen"]) {
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
        NSLog(@"もしviewControllerだったら");
        if ([transitionInfo[@"childObjectId"] isEqualToString:currentChildObjectId]) {
            NSLog(@"もしこどもが一致していたら");
            returnDic[@"nextVC"] = [self uploadType];
            if ([transitionInfo[@"event"] isEqualToString:@"imageUpload"] || [transitionInfo[@"event"] isEqualToString:@"bestShotChosen"]) {
                // 画像アップロードの場合、遷移はこれで終わりなのでtransitionInfoを初期化
                [self removeInfo];
            }
        } else {
            NSLog(@"もしこどもが一致していなかったら");
            returnDic[@"nextVC"] = @"movePageContentViewController";
            transitionInfo[@"isMoving"] = [NSNumber numberWithBool:YES];
        }
        return returnDic;
    } else if ([currentViewController[@"viewController"] isEqualToString:@"MultiUploadViewController"]) {
        NSLog(@"もしMultiUploadViewControllerだったら");
        if ([currentDate isEqualToString:transitionInfo[@"date"]] && [currentChildObjectId isEqualToString:transitionInfo[@"childObjectId"]]) {
            NSLog(@"もし日付とこどもが一致していたら");
            if ([transitionInfo[@"event"] isEqualToString:@"imageUpload"] || [transitionInfo[@"event"] isEqualToString:@"bestShotChosen"]) {
                NSLog(@"imageUploadなら");
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
                NSLog(@"commentPostedなら");
                // 対象の日付、対象のこどものMultiUploadViewが開かれている状態
                // ベストショットがあればベストショット、決まってなければ最初の画像を開く
                NSLog(@"ベストショットがあればベストショット、決まってなければ最初の画像を開く");
                returnDic[@"nextVC"] = @"CommentViewController";
                return returnDic;
            }
        }
        [self returnToRoot:viewController];
        return nil;
    } else if ([currentViewController[@"viewController"] isEqualToString:@"ImagePageViewController"]) {
        NSLog(@"もしImagePageViewControllerだったら");
        if ([currentDate isEqualToString:transitionInfo[@"date"]] && [currentChildObjectId isEqualToString:transitionInfo[@"childObjectId"]]) {
            NSLog(@"もし日付とこどもが一致していたら");
            if ([transitionInfo[@"event"] isEqualToString:@"imageUpload"]) {
                NSLog(@"imageUploadなら");
                // MultiUploadと同様
                // notificationの方がまだましな気がしてきた
                UploadViewController *vC = (UploadViewController *)[viewController.navigationController topViewController];
                if (vC && [NSStringFromClass([vC class]) isEqualToString:@"UploadViewController"]) {
                    [vC viewDidLoad];
                }
                
                [self removeInfo];
                return nil;
            } else if ([transitionInfo[@"event"] isEqualToString:@"commentPosted"]) {
                NSLog(@"commentPostedなら");
                // 対象の日付、対象のこどものMultiUploadViewが開かれている状態
                // コメントを開く
                NSLog(@"コメントを開く");
            }
        }
        [self returnToRoot:viewController];
        return nil;
    } else {
        NSLog(@"その他のViewControllerなら");
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
    NSLog(@"topにもどろう");
    if (![transitionInfo[@"isMoving"] isEqualToNumber:[NSNumber numberWithBool:YES]]) {
        transitionInfo[@"isMoving"] = [NSNumber numberWithBool:YES];
        [viewController.navigationController setNavigationBarHidden:NO];
        [viewController.navigationController popToRootViewControllerAnimated:YES];
        
        NSNotification *n = [NSNotification notificationWithName:@"childPropertiesChanged" object:nil];
        [[NSNotificationCenter defaultCenter] postNotification:n];
    }
}

@end
