//
//  NotificationHistory.m
//  babyry
//
//  Created by hirata.motoi on 2014/08/07.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "NotificationHistory.h"
#import "DateUtils.h"

@implementation NotificationHistory

NSString *const className = @"NotificationHistory";

+ (void)createNotificationHistoryWithType:(NSString *)type withTo:(NSString *)userId withDate:(NSInteger )date
{
    NSLog(@"createNotificationHistoryWithType type:%@ userId:%@ date:%ld", type, userId, date);
   
    // default値
    if (type.length < 1 || userId.length < 1 || !date) {
        return;
    }
    
    PFObject *nh = [PFObject objectWithClassName:className];
    nh[@"type"] = type;
    nh[@"toUserId"] = userId;
    nh[@"date"] = [NSNumber numberWithInteger:date];
    nh[@"status"] = @"ready";
    [nh saveInBackground];
}

+ (void)getNotificationHistoryInBackground: userId withType:(NSString *)type withBlock:(NotificationHistoryBlock)block
{
    NSMutableDictionary *history = [[NSMutableDictionary alloc]init];
    PFQuery *query = [PFQuery queryWithClassName:className];
    [query whereKey:@"toUserId" equalTo:userId];
    [query whereKey:@"status" equalTo:@"ready"];
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
        }
    }];
}

+ (void)disableDisplayedNotificationsWithObject:(PFObject *)object
{
    object[@"status"] = @"displayed";
    [object saveInBackground];
}

@end
