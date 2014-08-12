//
//  NotificationHistory.h
//  babyry
//
//  Created by hirata.motoi on 2014/08/07.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

typedef void (^NotificationHistoryBlock)(NSMutableDictionary *history);

@interface NotificationHistory : NSObject

+ (void)createNotificationHistoryWithType:(NSString *)type withTo:(NSString *)userId withDate:(NSString *)dateString;
+ (void)getNotificationHistoryInBackground: userId withType:(NSString *)type withBlock:(NotificationHistoryBlock)block;
+ (void)disableDisplayedNotificationsWithObject:(PFObject *)object;

@end
