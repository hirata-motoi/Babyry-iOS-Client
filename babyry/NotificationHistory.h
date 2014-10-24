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
typedef void (^NotificationHistoryObjectsBlock)(NSArray *objects);

@interface NotificationHistory : NSObject

+ (void)createNotificationHistoryWithType:(NSString *)type withTo:(NSString *)userId withChild:(NSString *)childObjectId withDate:(NSInteger)date;
+ (void)getNotificationHistoryInBackground: userId withType:(NSString *)type withChild:(NSString *)childObjectId withBlock:(NotificationHistoryBlock)block;
+ (void)getNotificationHistoryObjectsByDateInBackground:userId withType:(NSString *)type withChild:(NSString *)childObjectId date:(NSNumber *)date withBlock:(NotificationHistoryObjectsBlock)block;
+ (void)disableDisplayedNotificationsWithObject:(PFObject *)object;

@end
