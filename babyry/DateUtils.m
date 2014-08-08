//
//  DateUtils.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/07/15.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "DateUtils.h"

@implementation DateUtils

// システムのタイムゾーンに直す的な関数
+(NSDate *) setSystemTimezone:date
{
    NSDate *sourceDate = [NSDate dateWithTimeIntervalSinceNow:3600*24*60];
    NSTimeZone* destinationTimeZone = [NSTimeZone systemTimeZone];
    float timeZoneOffset = [destinationTimeZone secondsFromGMTForDate:sourceDate];
    NSDate *localDate = [date dateByAddingTimeInterval:timeZoneOffset];
    
    return localDate;
}

// 0時にする
+(NSDate *) setZero:date
{
    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSUInteger flags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit ;
    NSDateComponents *comps = [cal components:flags fromDate:date];
    NSDate *zero = [cal dateFromComponents:comps];
    
    return zero;
}

// タイムゾーン+0時設定
+(NSDate *) setSystemTimezoneAndZero:date
{
    return [self setSystemTimezone:[self setZero:date]];
}

+ (NSDateComponents *)dateCompsFromDate:(NSDate *)date
{
    if (date == nil) {
        date = [NSDate date];
    }
    
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *dateComps = [cal components:
        NSYearCalendarUnit   |
        NSMonthCalendarUnit  |
        NSDayCalendarUnit    |
        NSHourCalendarUnit
    fromDate:date];
    return dateComps;
}


@end
