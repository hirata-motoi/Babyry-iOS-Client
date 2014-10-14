//
//  TransitionByPushNotification.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/10/01.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TransitionByPushNotification : NSObject

+ (void) setInfo:(NSMutableDictionary *)transitionInfo;
+ (NSDictionary *) getInfo;
+ (void) removeInfo;
+ (void) setCurrentViewController:(NSString *)viewController;
+ (NSString *) getCurrentViewController;
+ (void) setCurrentPageIndex:(int)index;
+ (int) getCurrentPageIndex;
+ (NSMutableDictionary *) dispatch:(UIViewController *)viewController childObjectId:(NSString *)childObjectId selectedDate:(NSString *)selectedDate;
+ (void) setCurrentDate:(NSString *)ymd;
+ (NSString *)getCurrentDate;

@end
