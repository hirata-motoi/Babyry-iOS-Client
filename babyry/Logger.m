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

@end
