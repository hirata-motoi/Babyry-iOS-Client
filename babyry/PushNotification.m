//
//  PushNotification.m
//  babyry
//
//  Created by 平田基 on 2014/07/17.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "PushNotification.h"
#import "Partner.h"

@implementation PushNotification

+ (void)sendInBackground:(NSString *)event withOptions:(NSDictionary *)options
{
    // eventから送信メッセージを取得(これはDBで変えれるように)
    PFQuery *query = [PFQuery queryWithClassName:@"PushNotificationEvent"];
    [query whereKey:@"event" equalTo:event];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error && objects.count > 0) { // 存在しないイベントの場合は通知を送らない
            PFObject *eventInfo = [objects objectAtIndex:0];
            
            NSString *message = eventInfo[@"message"];
            if (eventInfo[@"formatArgsCount"] && [options objectForKey:@"formatArgs"]) {
                message = [NSString stringWithFormat:message, [options objectForKey:@"formatArgs"]];
            }
            
            // 相方の情報を取得
            PFQuery *queryFamily = [PFQuery queryWithClassName:@"_User"];
            [queryFamily whereKey:@"familyId" equalTo:[PFUser currentUser][@"familyId"]];
            [queryFamily whereKey:@"userId" notEqualTo:[PFUser currentUser][@"userId"]];
            queryFamily.cachePolicy = kPFCachePolicyCacheElseNetwork;
            [queryFamily findObjectsInBackgroundWithBlock:^(NSArray *familyObjects, NSError *familyError){
                if (!error && familyObjects.count > 0) { // familyが自分だけだったら送らない
                    PFPush *push = [[PFPush alloc]init];
                    
                    // デフォルトのchannels(family)をセット
                    NSMutableArray *familyUserIds = [[NSMutableArray alloc]init];
                    for (PFObject *user in familyObjects) {
                        [familyUserIds addObject:[NSString stringWithFormat:@"userId_%@", user[@"userId"]]];
                    }
                    
                    [push setChannels:familyUserIds];
                    
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
                    
                    NSMutableDictionary *data = options[@"data"];
                    if (!data) {
                        data = [[NSMutableDictionary alloc]init];
                    }
                    // オプションでdataが指定された場合はセット(eventを元にセットされたメッセージは上書きされる)
                    if (!data[@"alert"]) {
                        data[@"alert"] = message;
                    }
                    if (!data[@"sound"]) {
                        // デフォルトの着信音
                        data[@"sound"] = @"";
                    }
                    [push setData:[options objectForKey:@"data"]];
                    
                    // 送信
                    [push sendPushInBackground];
                }
            }];
            

        }
    }];
}

// このdeviceが自分以外に紐づいている場合は上書きする
+ (void)setupPushNotificationInstallation
{
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    PFUser *currentUser = [PFUser currentUser];
    
    // 未ログインの場合は何もしない
    if (!currentUser[@"userId"]) {
        return;
    }
    
    // currentInstallationがない場合(AppDelegateで処理するので基本はないはず)、ここでdeviceTokenを発行
    // TODO implement
    
    // PFInstallationへのaddとremoveは同時にはできないので、仕方なく2回リクエストを送る
    // 自分のIDはとりあえず追加
    if (currentInstallation.objectId) {
        [currentInstallation refresh];
    }
    [currentInstallation addUniqueObject:[NSString stringWithFormat:@"userId_%@", currentUser[@"userId"]] forKey:@"channels"];
    [currentInstallation saveInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
        if (succeeded) {
            // 自分以外のユーザのIDがあれば消す
            NSMutableArray *userIds = [self extractUserIdsFromChannels:[PFInstallation currentInstallation]];
            for (NSString *userId in userIds) {
                if (! [userId isEqualToString:currentUser[@"userId"]]) {
                    [currentInstallation removeObject:[NSString stringWithFormat:@"userId_%@", userId] forKey:@"channels"];
                }
            }
            [currentInstallation saveInBackground];
        }
    }];
}
     
+ (NSMutableArray *)extractUserIdsFromChannels: (PFInstallation *)currentInstallation
{
    NSMutableArray *userIds = [[NSMutableArray alloc]init];
    
    NSError *error = nil;
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"userId_(.*)" options:NSRegularExpressionCaseInsensitive error:&error];
    if (error == nil) {
        for (NSString *channel in currentInstallation[@"channels"]) {
            NSTextCheckingResult *match= [regex firstMatchInString:channel options:0 range:NSMakeRange(0, channel.length)];
            if (match) {
                NSString *userId = [channel substringWithRange:[match rangeAtIndex:1]];
                [userIds addObject:userId];
            }
        }
    }
    return userIds;
}

+ (void)removeSelfUserIdFromChannels:(PushNotificationBlock)block
{
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    // 自分のuserIdを消す
    NSString *targetChannel = [NSString stringWithFormat:@"userId_%@", [PFUser currentUser][@"userId"]];
    [currentInstallation removeObject:targetChannel forKey:@"channels"];
    [currentInstallation saveEventually:^(BOOL succeeded, NSError *error) {
        // succeededでもerrorでも次の処理に進ませる
        block();
    }];
}

@end
