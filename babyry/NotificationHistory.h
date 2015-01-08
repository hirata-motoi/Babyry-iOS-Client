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
typedef void (^DeleteNotificationHistoryBlock)(void);

@interface NotificationHistory : NSObject

+ (void)createNotificationHistoryWithType:(NSString *)type withTo:(NSString *)userId withChild:(NSString *)childObjectId withDate:(NSInteger)date;
+ (void)getNotificationHistoryInBackgroundGroupByDate:userId withType:(NSString *)type withChild:(NSString *)childObjectId withStatus:(NSString *)status withLimit:(int)limit withBlock:(NotificationHistoryBlock)block;
+ (void)getNotificationHistoryInBackground:userId withType:(NSString *)type withChild:(NSString *)childObjectId withStatus:(NSString *)status withLimit:(int)limit withBlock:(NotificationHistoryObjectsBlock)block;
+ (void)getNotificationHistoryObjectsByDateInBackground:userId withType:(NSString *)type withChild:(NSString *)childObjectId date:(NSNumber *)date withBlock:(NotificationHistoryObjectsBlock)block;
+ (void)disableDisplayedNotificationsWithObject:(PFObject *)object;
+ (void)disableDisplayedNotificationsWithObject:(PFObject *)object withBlock:(DeleteNotificationHistoryBlock)block;
+ (NSString *)getNotificationString:(PFObject *)histObject;

@end
