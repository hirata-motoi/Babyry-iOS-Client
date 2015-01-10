//
//  TransitionByPushNotification.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/10/01.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

@interface TransitionByPushNotification : NSObject

+ (void) setInfo:(NSMutableDictionary *)transitionInfo;
+ (NSDictionary *) getInfo;
+ (void) removeInfo;
+ (void) setCurrentViewController:(NSString *)viewController;
+ (NSString *) getCurrentViewController;
+ (void) setCurrentDate:(NSString *)date;
+ (NSString *) getCurrentDate;
+ (void) setCurrentPageIndex:(int)index;
+ (int) getCurrentPageIndex;
+ (void)dispatch:(UIViewController *)vc;
+ (void)returnToTop:(UIViewController *)vc;
+ (BOOL)isReturnedToTop;
+ (void) setCommentViewOpenFlag:(BOOL)openFlag;
+ (void) setAppLaunchedFlag;
+ (void) removeAppLaunchFlag;
+ (BOOL) checkAppLaunchedFlag;
+ (void)createTransitionInfoAntTransition:(PFObject *)histObject viewController:(UIViewController *)vc;

@end
