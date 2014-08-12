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

+ (void)createNotificationHistoryWithType:(NSString *)type withTo:(NSString *)userId withDate:(NSString *)dateString
{
    NSLog(@"createNotificationHistoryWithType type:%@ userId:%@ date:%@", type, userId, dateString);
   
    // default値
    if (type == nil) {
        type = @"bestShotChage";
    }
    
    PFObject *nh = [PFObject objectWithClassName:className];
    nh[@"type"] = type;
    nh[@"toUserId"] = userId;
    nh[@"dateString"] = [NSString stringWithFormat:@"D%@", dateString];
    nh[@"status"] = @"ready";
    [nh saveInBackground];
}

+ (void)getNotificationHistoryInBackground: userId withType:(NSString *)type withBlock:(NotificationHistoryBlock)block
{
    NSMutableDictionary *history = [[NSMutableDictionary alloc]init];
    PFQuery *query = [PFQuery queryWithClassName:className];
    [query whereKey:@"toUserId" equalTo:userId];
    if (type != nil) {
        [query whereKey:@"type" equalTo:type];
    }
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if (!error) {
            for (PFObject *object in objects) {
                NSString *ymd = [object[@"dateString"] substringWithRange:NSMakeRange(1, 8)];
               
                NSMutableArray *historiesByYMD = [history objectForKey:ymd];
                if (!historiesByYMD) {
                    historiesByYMD = [[NSMutableArray alloc]init];
                    [history setObject:historiesByYMD forKey:ymd];
                }
                
                [historiesByYMD addObject:object];
            }
            NSLog(@"history : %@", history);
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
