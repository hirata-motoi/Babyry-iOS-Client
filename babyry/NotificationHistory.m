//
//  NotificationHistory.m
//  babyry
//
//  Created by hirata.motoi on 2014/08/07.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "NotificationHistory.h"
#import "DateUtils.h"
#import "Logger.h"

@implementation NotificationHistory

NSString *const className = @"NotificationHistory";

+ (void)createNotificationHistoryWithType:(NSString *)type withTo:(NSString *)userId withChild:(NSString *)childObjectId withDate:(NSInteger )date
{
    // default値
    if (type.length < 1 || userId.length < 1 || !date || !childObjectId) {
        return;
    }
    
    PFObject *nh = [PFObject objectWithClassName:className];
    nh[@"type"] = type;
    nh[@"toUserId"] = userId;
    nh[@"date"] = [NSNumber numberWithInteger:date];
    nh[@"child"] = childObjectId;
    nh[@"status"] = @"ready";
    [nh saveInBackground];
}

+ (void)getNotificationHistoryInBackground:userId withType:(NSString *)type withChild:(NSString *)childObjectId withBlock:(NotificationHistoryBlock)block
{
    NSMutableDictionary *history = [[NSMutableDictionary alloc]init];
    PFQuery *query = [PFQuery queryWithClassName:className];
    [query whereKey:@"toUserId" equalTo:userId];
    [query whereKey:@"status" equalTo:@"ready"];
    [query whereKey:@"child" equalTo:childObjectId];
    query.limit = 1000; // max
    if (type != nil) {
        [query whereKey:@"type" equalTo:type];
    }
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if (!error) {
            for (PFObject *object in objects) {
                //NSString *ymd = [object[@"dateString"] substringWithRange:NSMakeRange(1, 8)];
                NSNumber *dateNumber = object[@"date"];
                NSString *dateString = [dateNumber stringValue];
                NSString *year  = [dateString substringWithRange:NSMakeRange(0, 4)];
                NSString *month = [dateString substringWithRange:NSMakeRange(4, 2)];
                NSString *day   = [dateString substringWithRange:NSMakeRange(6, 2)];
                
                NSString *ymd = [NSString stringWithFormat:@"%@%@%@", year, month, day];
               
                NSMutableDictionary *historiesByYMD = [history objectForKey:ymd];
                if (!historiesByYMD) {                
                    historiesByYMD = [[NSMutableDictionary alloc]init];
                    [history setObject:historiesByYMD forKey:ymd];
                }
                
                NSMutableArray *objectsByType = historiesByYMD[object[@"type"]];
                if (!objectsByType) {
                    objectsByType = [[NSMutableArray alloc]init];
                    [historiesByYMD setObject:objectsByType forKey:object[@"type"]];
                }                             
                
                [objectsByType addObject:object];
            }
            block(history);
        } else {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in getNotificationHistoryInBackground(findObjectsInBackgroundWithBlock) : %@", error]];
        }
    }];
}

+ (void)getNotificationHistoryObjectsByDateInBackground:userId withType:(NSString *)type withChild:(NSString *)childObjectId date:(NSNumber *)date withBlock:(NotificationHistoryObjectsBlock)block
{
    PFQuery *query = [PFQuery queryWithClassName:className];
    [query whereKey:@"toUserId" equalTo:userId];
    [query whereKey:@"status" equalTo:@"ready"];
    [query whereKey:@"child" equalTo:childObjectId];
    [query whereKey:@"date" equalTo:date];
    query.limit = 1000; // max
    if (type != nil) {
        [query whereKey:@"type" equalTo:type];
    }
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if (!error) {
            block(objects);
        } else {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in getNotificationHistoryObjectsByDateInBackground : %@", error]];
        }
    }];
}

+ (void)disableDisplayedNotificationsWithObject:(PFObject *)object
{
    object[@"status"] = @"displayed";
    [object saveInBackground];
}

@end
