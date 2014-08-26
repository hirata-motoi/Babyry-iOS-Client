//
//  Logger.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/08/26.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "Logger.h"

@implementation Logger

+ (void) writeParse:(NSString *)type message:(NSString *)message
{
    NSString *className = ([type isEqualToString:@"crit"]) ? @"CritLog" : ([type isEqualToString:@"warn"]) ? @"WarnLog" : ([type isEqualToString:@"info"]) ? @"InfoLog" : @"";
    
    if ([className isEqualToString:@""]) {
        [self writeParse:@"crit" message:[NSString stringWithFormat:@"Invalid Log Type %@ : message is %@", type, message]];
    }
    
    PFObject *logObject = [PFObject objectWithClassName:className];
    logObject[@"message"] = message;
    if ([PFUser currentUser]) {
        logObject[@"userId"] = [PFUser currentUser].objectId;
    }
    [logObject saveInBackground];
}

@end
