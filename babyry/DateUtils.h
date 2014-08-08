//
//  DateUtils.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/07/15.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DateUtils : NSObject

+(NSDate *) setSystemTimezone:date;
+(NSDate *) setZero:date;
+(NSDate *) setSystemTimezoneAndZero:date;
+ (NSDateComponents *)dateCompsFromDate:(NSDate *)date;

@end
