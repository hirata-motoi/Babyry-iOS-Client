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
    
    if ([transitionInfo[@"event"] isEqualToString:@"imageUpload"]) {
        returnDic = [self dispatchForImageUpload:viewController childObjectId:currentChildObjectId selectedDate:currentDate];
    }
    
    return returnDic;
}

+ (NSMutableDictionary *)dispatchForImageUpload:(UIViewController *)viewController childObjectId:(NSString *)currentChildObjectId selectedDate:(NSString *)currentDate
{
    // 起動一発目は値が入らない かつ 一発目は必ずtopのViewControllerが入るので
    if (!currentViewController[@"viewController"]) {
        currentViewController[@"viewController"] = @"ViewController";
    }
    
    if ([currentViewController[@"viewController"] isEqualToString:@"ViewController"]) {
        if ([transitionInfo[@"childObjectId"] isEqualToString:currentChildObjectId]) {
            returnDic[@"nextVC"] = [self uploadType];
            // 遷移はこれで終わりなので、transitionInfoを初期化
            [self removeInfo];
        } else {
            returnDic[@"nextVC"] = @"movePageContentViewController";
            transitionInfo[@"isMoving"] = [NSNumber numberWithBool:YES];
        }
        return returnDic;
    } else if ([currentViewController[@"viewController"] isEqualToString:@"MultiUploadViewController"]) {
        if ([currentDate isEqualToString:transitionInfo[@"date"]] && [currentChildObjectId isEqualToString:transitionInfo[@"childObjectId"]]) {
            
            // ここでMultiUploadViewControllerのうまいreloadの仕方が思いつかない
            // notificationの方がまだましな気がしてきた
            MultiUploadViewController *vC = (MultiUploadViewController *)[viewController.navigationController topViewController];
            if (vC && [NSStringFromClass([vC class]) isEqualToString:@"MultiUploadViewController"]) {
                [vC viewDidAppear:YES];
            }
            
            [self removeInfo];
            return nil;
        }
        [self returnToRoot:viewController];
        return nil;
    } else if ([currentViewController[@"viewController"] isEqualToString:@"ImagePageViewController"]) {
        if ([currentDate isEqualToString:transitionInfo[@"date"]] && [currentChildObjectId isEqualToString:transitionInfo[@"childObjectId"]]) {
            
            // MultiUploadと同様
            // notificationの方がまだましな気がしてきた
            UploadViewController *vC = (UploadViewController *)[viewController.navigationController topViewController];
            if (vC && [NSStringFromClass([vC class]) isEqualToString:@"UploadViewController"]) {
                [vC viewDidLoad];
            }
            
            [self removeInfo];
            return nil;
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
    if (![transitionInfo[@"isMoving"] isEqualToNumber:[NSNumber numberWithBool:YES]]) {
        transitionInfo[@"isMoving"] = [NSNumber numberWithBool:YES];
        [viewController.navigationController setNavigationBarHidden:NO];
        [viewController.navigationController popToRootViewControllerAnimated:YES];
        
        NSNotification *n = [NSNotification notificationWithName:@"childPropertiesChanged" object:nil];
        [[NSNotificationCenter defaultCenter] postNotification:n];
    }
}

@end
