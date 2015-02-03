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
#import "ChildProperties.h"
#import "Config.h"

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

// いつか使うかもしれんのでコメントだけ
//+ (void)getNotificationHistoryInBackgroundGroupByDate:userId withType:(NSString *)type withChild:(NSString *)childObjectId withStatus:(NSString *)status withLimit:(int)limit withBlock:(NotificationHistoryBlock)block
//{
//    NSMutableDictionary *history = [[NSMutableDictionary alloc]init];
//    PFQuery *query = [PFQuery queryWithClassName:className];
//    [query whereKey:@"toUserId" equalTo:userId];
//    if (status) {
//        [query whereKey:@"status" equalTo:status];
//    } else {
//        [query whereKey:@"status" notEqualTo:@"removed"];
//    }
//    if (childObjectId != nil) {
//        [query whereKey:@"child" equalTo:childObjectId];
//    }
//    query.limit = limit;
//    if (type != nil) {
//        [query whereKey:@"type" equalTo:type];
//    }
//    [query orderByDescending:@"createdAt"];
//    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
//        if (!error) {
//            for (PFObject *object in objects) {
//                //NSString *ymd = [object[@"dateString"] substringWithRange:NSMakeRange(1, 8)];
//                NSNumber *dateNumber = object[@"date"];
//                NSString *dateString = [dateNumber stringValue];
//                NSString *year  = [dateString substringWithRange:NSMakeRange(0, 4)];
//                NSString *month = [dateString substringWithRange:NSMakeRange(4, 2)];
//                NSString *day   = [dateString substringWithRange:NSMakeRange(6, 2)];
//                
//                NSString *ymd = [NSString stringWithFormat:@"%@%@%@", year, month, day];
//               
//                NSMutableDictionary *historiesByYMD = [history objectForKey:ymd];
//                if (!historiesByYMD) {                
//                    historiesByYMD = [[NSMutableDictionary alloc]init];
//                    [history setObject:historiesByYMD forKey:ymd];
//                }
//                
//                NSMutableArray *objectsByType = historiesByYMD[object[@"type"]];
//                if (!objectsByType) {
//                    objectsByType = [[NSMutableArray alloc]init];
//                    [historiesByYMD setObject:objectsByType forKey:object[@"type"]];
//                }                             
//                
//                [objectsByType addObject:object];
//            }
//            block(history);
//        } else {
//            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in getNotificationHistoryInBackground(findObjectsInBackgroundWithBlock) : %@", error]];
//        }
//    }];
//}

+ (void)getNotificationHistoryInBackground:userId withType:(NSString *)type withChild:(NSString *)childObjectId withStatus:(NSString *)status withLimit:(int)limit withBlock:(NotificationHistoryObjectsBlock)block
{
    PFQuery *query = [PFQuery queryWithClassName:className];
    [query whereKey:@"toUserId" equalTo:userId];
    if (status) {
        [query whereKey:@"status" equalTo:status];
    } else {
        [query whereKey:@"status" notEqualTo:@"removed"];
    }
    if (childObjectId != nil) {
        [query whereKey:@"child" equalTo:childObjectId];
    } else {
        NSMutableArray *childProperties = [ChildProperties getChildProperties];
        NSMutableArray *childObjectIds = [[NSMutableArray alloc] init];
        for (NSDictionary *childProperty in childProperties) {
            [childObjectIds addObject:childProperty[@"objectId"]];
        }
        [query whereKey:@"child" containedIn:childObjectIds];
    }
    query.limit = limit;
    if (type != nil) {
        [query whereKey:@"type" equalTo:type];
    }
    [query orderByDescending:@"createdAt"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if (!error) {
            NSMutableDictionary *notificationHistoryDic = [[NSMutableDictionary alloc] init];
            // imageUploaded => 2日以内のみ表示 => 同じ日付・同じ子供はまとめて表示
            // requestPhoto => 2日以内のみ表示 => 同じ日付・同じ子供はまとめて表示
            // bestShotChanged => ずっと表示 => 同じ日付・同じ子供はまとめて表示
            // commentPosted => ずっと表示 => 同じ日付・同じ子供はまとめて表示
        
            // 以下のデータ構造でハッシュを作成
            // childObjectId -> notificationType -> date -> {num, createdAt, status}
            // 同じお知らせの中でcreatedAtが一番新しいものを、代表のcreatedAtとして保持
            for (PFObject *object in objects) {
                NSString *childId = object[@"child"];
                NSString *type = object[@"type"];
                NSString *date = object[@"date"];
                
                // 2日以上前のimageUploaded, requestPhotは除外
                if ([type isEqualToString:@"imageUploaded"] || [type isEqualToString:@"requestPhot"]) {
                    NSNumber *yesterdayYMD = [DateUtils getYesterdayYMD];
                    if ([yesterdayYMD intValue] > [date intValue]) {
                        continue;
                    }
                }
                
                // imageUploaded, requestPhoto, bestShotChanged, commentPostedだけ拾う
                // その他のやつはhistoryにある意味が無いので(partchangeはかってにスイッチされてるとか)
                if (![[Config config][@"GlobalNotificationTypes"] containsObject:type]) {
                    continue;
                }
                
                if (notificationHistoryDic[childId][type][date]) {
                    int num = [notificationHistoryDic[childId][type][date][@"num"] intValue] + 1;
                    notificationHistoryDic[childId][type][date][@"num"] = [NSNumber numberWithInt:num];
                    if ([object.createdAt compare:notificationHistoryDic[childId][type][date][@"lastCreatedAt"]] == NSOrderedDescending) {
                        notificationHistoryDic[childId][type][date][@"lastCreatedAt"] = object.createdAt;
                    }
                    if ([object[@"status"] isEqualToString:@"ready"]) {
                        notificationHistoryDic[childId][type][date][@"status"] = @"ready";
                    }
                } else if (notificationHistoryDic[childId][type]) {
                    notificationHistoryDic[childId][type][date] = [[NSMutableDictionary alloc] init];
                    notificationHistoryDic[childId][type][date][@"num"] = [NSNumber numberWithInt:1];
                    notificationHistoryDic[childId][type][date][@"lastCreatedAt"] = object.createdAt;
                    notificationHistoryDic[childId][type][date][@"status"] = object[@"status"];
                } else if (notificationHistoryDic[childId]) {
                    NSMutableDictionary *dateDic = [[NSMutableDictionary alloc] init];
                    dateDic[@"num"] = [NSNumber numberWithInt:1];
                    dateDic[@"lastCreatedAt"] = object.createdAt;
                    dateDic[@"status"] = object[@"status"];
                    NSMutableDictionary *typeDic = [[NSMutableDictionary alloc] init];
                    typeDic[date] = dateDic;
                    notificationHistoryDic[childId][type] = typeDic;
                } else {
                    NSMutableDictionary *dateDic = [[NSMutableDictionary alloc] init];
                    dateDic[@"num"] = [NSNumber numberWithInt:1];
                    dateDic[@"lastCreatedAt"] = object.createdAt;
                    dateDic[@"status"] = object[@"status"];
                    NSMutableDictionary *typeDic = [[NSMutableDictionary alloc] init];
                    typeDic[date] = dateDic;
                    NSMutableDictionary *childDic = [[NSMutableDictionary alloc] init];
                    childDic[type] = typeDic;
                    notificationHistoryDic[childId] = childDic;
                }
            }
            
            // 時系列で並べる為、lastCreatedAtをkeyにしたハッシュに作り替える
            NSMutableDictionary *notificationHistoryDicByDate = [[NSMutableDictionary alloc] init];
            for (NSString *childId in [notificationHistoryDic allKeys]) {
                for (NSString *type in [notificationHistoryDic[childId] allKeys]) {
                    for (NSDictionary *date in [notificationHistoryDic[childId][type] allKeys]) {
                        NSDate *lastCreatedAt = notificationHistoryDic[childId][type][date][@"lastCreatedAt"];
                        NSMutableDictionary *infoDic = [[NSMutableDictionary alloc] init];
                        infoDic[@"child"] = childId;
                        infoDic[@"type"] = type;
                        infoDic[@"date"] = date;
                        infoDic[@"status"] = notificationHistoryDic[childId][type][date][@"status"];
                        infoDic[@"num"] = notificationHistoryDic[childId][type][date][@"num"];
                        notificationHistoryDicByDate[lastCreatedAt] = infoDic;
                    }
                }
            }
            
            // createdAtで並び替えた配列にする
            NSArray *keys = [notificationHistoryDicByDate allKeys];
            keys = [keys sortedArrayUsingComparator:^(id o1, id o2) {
                return [o2 compare:o1];
            }];
            
            NSMutableArray *notificationHistoryArray = [[NSMutableArray alloc] init];
            for (id key in keys) {
                [notificationHistoryArray addObject:notificationHistoryDicByDate[key]];
            }
            
            block(notificationHistoryArray);
        } else {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in getNotificationHistoryInBackground(findObjectsInBackgroundWithBlock) : %@", error]];
        }
    }];
}

+ (void)getNotificationHistoryLessThanTargetDateInBackground:userId withType:(NSString *)type withChild:(NSString *)childObjectId withStatus:(NSString *)status withLimit:(int)limit withLimitDate:(NSNumber *)date withBlock:(NotificationHistoryObjectsBlock)block
{
    PFQuery *query = [PFQuery queryWithClassName:className];
    [query whereKey:@"toUserId" equalTo:userId];
    if (status) {
        [query whereKey:@"status" equalTo:status];
    } else {
        [query whereKey:@"status" notEqualTo:@"removed"];
    }
    if (childObjectId != nil) {
        [query whereKey:@"child" equalTo:childObjectId];
    }
    [query whereKey:@"date" lessThan:date];
    query.limit = limit;
    if (type != nil) {
        [query whereKey:@"type" equalTo:type];
    }
    [query orderByDescending:@"createdAt"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if (!error) {
            block(objects);
        } else {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in getNotificationHistoryLessThanTargetDateInBackground(findObjectsInBackgroundWithBlock) : %@", error]];
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
    [query orderByDescending:@"createdAt"];
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

+ (void)disableDisplayedNotificationsWithObject:(PFObject *)object withBlock:(DeleteNotificationHistoryBlock)block
{
    object[@"status"] = @"displayed";
    [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        block();
    }];
}

+ (void)disableDisplayedNotificationsWithUser:(NSString *)userId withChild:(NSString *)childObjectId withDate:(NSString *)date withType:(NSArray *)types
{
    PFQuery *query = [PFQuery queryWithClassName:className];
    [query whereKey:@"toUserId" equalTo:userId];
    [query whereKey:@"status" equalTo:@"ready"];
    [query whereKey:@"child" equalTo:childObjectId];
    [query whereKey:@"date" equalTo:[NSNumber numberWithInt:[date intValue]]];
    [query whereKey:@"type" containedIn:types];
    query.limit = 1000; // max
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if (!error) {
            for (PFObject *object in objects) {
                object[@"status"] = @"displayed";
                [object saveInBackground];
            }
        } else {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in disableDisplayedNotificationsWithUser : %@", error]];
        }
    }];
}

+ (void)removeNotificationsWithChild:(NSString *)childObjectId withDate:(NSString *)date withStatus:(NSString *)status
{
    PFQuery *query = [PFQuery queryWithClassName:className];
    [query whereKey:@"child" equalTo:childObjectId];
    [query whereKey:@"date" equalTo:[NSNumber numberWithInt:[date intValue]]];
    if (status) {
        [query whereKey:@"status" equalTo:status];
    }
    query.limit = 1000; // max
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if (!error) {
            for (PFObject *object in objects) {
                object[@"status"] = @"removed";
                [object saveInBackground];
            }
        } else {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in removeNotificationsWithUser : %@", error]];
        }
    }];
}

+ (NSString *)getNotificationString:(PFObject *)histObject
{
    NSString *returnStr;
    NSString *dateStr = [histObject[@"date"] stringValue];
    NSString *MMDD = [NSString stringWithFormat:@"%@/%@", [dateStr substringWithRange:NSMakeRange(4, 2)], [dateStr substringWithRange:NSMakeRange(6, 2)]];
    NSMutableDictionary *childProperty = [ChildProperties getChildProperty:histObject[@"child"]];
    if ([histObject[@"type"] isEqualToString:@"commentPosted"]) {
        returnStr = [NSString stringWithFormat:@"%@の%@ちゃんの写真にコメントが%@件つきました", MMDD, childProperty[@"name"], histObject[@"num"]];
    } else if ([histObject[@"type"] isEqualToString:@"requestPhoto"]) {
        returnStr = [NSString stringWithFormat:@"%@の%@ちゃんの写真がリクエストされています", MMDD, childProperty[@"name"]];
    } else if ([histObject[@"type"] isEqualToString:@"bestShotChanged"]) {
        returnStr = [NSString stringWithFormat:@"%@の%@ちゃんのベストショット決定！", MMDD, childProperty[@"name"]];
    } else if ([histObject[@"type"] isEqualToString:@"imageUploaded"]) {
        returnStr = [NSString stringWithFormat:@"%@に%@ちゃんの写真がアップロードされました", MMDD, childProperty[@"name"]];
    } else {
        return @"";
        [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error there is no notification type like %@", histObject[@"type"]]];
    }
    return returnStr;
}

@end
