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

// weekday num to string
+(NSString *) getWeekStringFromNum:(int)weekDayNum
{
    switch (weekDayNum) {
        case 1:
            return @"SUN";
            break;

        case 2:
            return @"MON";
            break;
            
        case 3:
            return @"TUE";
            break;
            
        case 4:
            return @"WED";
            break;
            
        case 5:
            return @"THU";
            break;
            
        case 6:
            return @"FRI";
            break;
            
        case 7:
            return @"SAT";
            break;
            
        default:
            break;
    }
    return @"";
}

@end
