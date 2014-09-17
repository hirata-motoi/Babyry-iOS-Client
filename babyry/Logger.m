//
//  Logger.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/08/26.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "Logger.h"
#import "AppSetting.h"
#import "Config.h"
#import "TrackingLogEntity.h"
#import "DateUtils.h"

@implementation Logger

+ (void) writeOneShot:(NSString *)type message:(NSString *)message
{
    // prodでなければログに出す
    if(![[app env] isEqualToString:@"prod"]) {
        NSLog(@"[%@] %@", type, message);
    }
    
    NSString *className = ([type isEqualToString:@"crit"]) ? @"CritLog" : ([type isEqualToString:@"warn"]) ? @"WarnLog" : ([type isEqualToString:@"info"]) ? @"InfoLog" : @"";
    
    if ([className isEqualToString:@""]) {
        [self writeOneShot:@"crit" message:[NSString stringWithFormat:@"Invalid Log Type %@ : message is %@", type, message]];
        return;
    }
    
    PFObject *logObject = [PFObject objectWithClassName:className];
    logObject[@"message"] = message;
    if ([PFUser currentUser]) {
        logObject[@"userId"] = [PFUser currentUser].objectId;
    }
    
    AppSetting *as = [AppSetting MR_findFirstByAttribute:@"name" withValue:[Config config][@"UUIDKeyName"]];
    if (as) {                                                              
        logObject[@"UUID"] = as.value;
    }
    [logObject saveInBackground];
}

+ (void) resetTrackingLogName:(NSString *)type
{
    // たまっているLogをParseに。フォアグランドでログの名前の取得まですませてからBackgroundに処理をまわすので、次のロギングには影響しない。
    [self sendTrackingLog];
    
    NSLog(@"resetTrackingLogName");
    NSString *objectId = [PFUser currentUser].objectId ? [PFUser currentUser].objectId : @"NoObjectId";
    NSString *userId = [PFUser currentUser][@"userId"] ? [PFUser currentUser][@"userId"] : @"NoUserId";
    
    // ファイル名は、objectId-userId-yyyymmddhhmmss.txt
    NSCalendar* cal = [NSCalendar currentCalendar];
    NSUInteger flg = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
    NSDateComponents *comps = [cal components:flg fromDate:[DateUtils setSystemTimezone:[NSDate date]]];
    NSString *logName = [NSString stringWithFormat:@"%@-%@-%04d%02d%02d%02d%02d%02d.txt", objectId, userId, comps.year, comps.month, comps.day, comps.hour, comps.minute, comps.second];
    
    NSString *TrackingLogKeyName = [Config config][@"TrackingLogKeyName"];
    TrackingLogEntity *entity = [TrackingLogEntity MR_findFirstByAttribute:@"name" withValue:TrackingLogKeyName];
    
    if (entity) {
        entity.logName = logName;
    } else {
        TrackingLogEntity *newEntity = [TrackingLogEntity MR_createEntity];
        newEntity.name = TrackingLogKeyName;
        newEntity.logName = logName;
    }
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    
    // 完全に落とさないでバックグラウンドから復帰した場合、Navigationの遷移という形でhook出来ないので、最後に開いたViewController(= いま開いたViewController)を記録する
    if ([type isEqualToString:@"applicationWillEnterForeground"]) {
        [Logger writeToTrackingLog:[NSString stringWithFormat:@"%@ %@ %@ %@", [DateUtils setSystemTimezone:[NSDate date]], [PFUser currentUser].objectId, [PFUser currentUser][@"userId"], entity.lastViewController]];
    }
    
}

+ (void) writeToTrackingLog:(NSString *)message
{
    NSString *TrackingLogKeyName = [Config config][@"TrackingLogKeyName"];
    TrackingLogEntity *entity = [TrackingLogEntity MR_findFirstByAttribute:@"name" withValue:TrackingLogKeyName];
    if (!entity.logName) {
        // ここは起きえないけど、進んじゃうと落ちるからreturn
        return;
    }
    NSArray *logs = [message componentsSeparatedByString:@" "];
    entity.lastViewController = [logs lastObject];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask,
                                                         YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *trackingLogDirectory = [NSString stringWithFormat:@"%@/TrackingLog", documentsDirectory];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:trackingLogDirectory]) {
        NSError *error = nil;
        [fileManager createDirectoryAtPath:trackingLogDirectory withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    NSString *path = [trackingLogDirectory stringByAppendingPathComponent:entity.logName];
    
    if (![fileManager fileExistsAtPath:path]) {
        [fileManager createFileAtPath:path contents:[NSData data] attributes:nil];
    }
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:path];
    NSString *writeLine = [NSString stringWithFormat:@"%@\n", message];
    NSData *data = [NSData dataWithBytes:writeLine.UTF8String length:writeLine.length];

    [fileHandle seekToEndOfFile];
    [fileHandle writeData:data];
    [fileHandle synchronizeFile];
    [fileHandle closeFile];
}

+ (void) sendTrackingLog
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask,
                                                         YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *trackingLogDirectory = [NSString stringWithFormat:@"%@/TrackingLog", documentsDirectory];
    
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:trackingLogDirectory error:nil];
    for (NSString *file in files) {
        NSData *logData = [[NSData alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", trackingLogDirectory, file]];
        PFFile *logFile = [PFFile fileWithName:file data:logData contentType:@"text/plain"];
        
        PFObject *trackingLog = [PFObject objectWithClassName:@"TrackingLog"];
        trackingLog[@"logFile"] = logFile;
        [trackingLog saveInBackgroundWithBlock:^(BOOL succeeded, NSError *erro){
            if (succeeded) {
                [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@", trackingLogDirectory, file] error:nil];
            }
        }];
    }
}

@end
