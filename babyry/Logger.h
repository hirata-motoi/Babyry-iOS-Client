//
//  Logger.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/08/26.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

@interface Logger : NSObject

+ (void) writeOneShot:(NSString *)type message:(NSString *)message;
+ (void) resetTrackingLogName:(NSString *)type;
+ (void) writeToTrackingLog:(NSString *)message;
+ (void) sendTrackingLog;

@end
