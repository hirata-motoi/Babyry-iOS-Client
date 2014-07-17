//
//  PushNotification.m
//  babyry
//
//  Created by 平田基 on 2014/07/17.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "PushNotification.h"

@implementation PushNotification

+ (void)sendInBackground:(NSString *)event withOptions:(NSDictionary *)options
{
    // eventから送信メッセージを取得(これはDBで変えれるように)
    PFQuery *query = [PFQuery queryWithClassName:@"PushNotificationEvent"];
    [query whereKey:@"event" equalTo:event];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        NSLog(@"event objects : %@", objects);
        if (!error && objects.count > 0) { // 存在しないイベントの場合は通知を送らない
            PFObject *eventInfo = [objects objectAtIndex:0];
            
            NSLog(@"eventInfo : %@", eventInfo);
            
            NSString *message = eventInfo[@"message"];
            
            // 相方の情報を取得
            PFQuery *queryFamily = [PFQuery queryWithClassName:@"_User"];
            [queryFamily whereKey:@"familyId" equalTo:[PFUser currentUser][@"familyId"]];
            [queryFamily whereKey:@"userId" notEqualTo:[PFUser currentUser][@"userId"]];
            queryFamily.cachePolicy = kPFCachePolicyCacheElseNetwork;
            [queryFamily findObjectsInBackgroundWithBlock:^(NSArray *familyObjects, NSError *familyError){
                NSLog(@"familyObjects : %@", familyObjects);
                if (!error && familyObjects.count > 0) { // familyが自分だけだったら送らない
                    
                    NSLog(@"push notification send start");
                    
                    PFPush *push = [[PFPush alloc]init];
                    
                    // デフォルトのchannels(family)をセット
                    NSMutableArray *familyUserIds = [[NSMutableArray alloc]init];
                    for (PFObject *user in familyObjects) {
                        [familyUserIds addObject:user[@"userId"]];
                    }
                    
                    NSLog(@"familyUserIds : %@", familyUserIds);
                    [push setChannels:familyUserIds];
                    
                    // デフォルトのメッセージをセット
                    [push setMessage:message];
                    
                    // オプションで指定があればchannelsを上書き
                    if ([options objectForKey:@"channels"]) {
                        [push setChannel:[options objectForKey:@"channels"]];
                    }
                    
                    // オプションでqueryを指定した場合は使う
                    if ([options objectForKey:@"query"]) {
                        NSDictionary *queryDictionary = [options objectForKey:@"query"];
                        PFQuery *pushQuery = [PFInstallation query];
                        for (NSString *key in [queryDictionary allKeys]) {
                            [pushQuery whereKey:key equalTo:[queryDictionary objectForKey:key] ];
                        }
                        [push setQuery:pushQuery];
                    }
                    
                    // オプションでdataが指定された場合はセット(eventを元にセットされたメッセージは上書きされる)
                    if ([options objectForKey:@"data"]) {
                        [push setData:[options objectForKey:@"data"]];
                    }
                    
                    // 送信
                    [push sendPushInBackground];
                }
            }];
            

        }
    }];
}


@end
