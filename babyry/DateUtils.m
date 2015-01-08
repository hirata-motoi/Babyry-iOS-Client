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

+ (NSDateComponents *)addDateComps:(NSDateComponents *)comps withUnit:(NSString *)unit withValue:(NSInteger)value
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *base = [calendar dateFromComponents:comps];
   
    NSDateComponents *addComps = [[NSDateComponents alloc]init];
    
    if ([unit isEqualToString:@"year"]) {
        [addComps setYear:value];
    } else if ([unit isEqualToString:@"month"]) {
        [addComps setMonth:value];
    } else if ([unit isEqualToString:@"day"]) {
        [addComps setDay:value];
    } else if ([unit isEqualToString:@"hour"]) {
        [addComps setHour:value];
    } else if ([unit isEqualToString:@"minute"]) {
        [addComps setMinute:value];
    } else {
        [addComps setSecond:value];
    }
    NSDate *date = [calendar dateByAddingComponents:addComps toDate:base options:0];

    NSDateComponents *result = [calendar components:
        NSYearCalendarUnit  |
        NSMonthCalendarUnit |
        NSDayCalendarUnit   |
        NSHourCalendarUnit  |
        NSWeekdayCalendarUnit
    fromDate:date];
   
    return result;
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

+ (NSDateComponents *)compsFromNumber:(NSNumber *)date
{
    NSString *ymdString = [date stringValue];
    NSString *year  = [ymdString substringWithRange:NSMakeRange(0, 4)];
    NSString *month = [ymdString substringWithRange:NSMakeRange(4, 2)];
    NSString *day   = [ymdString substringWithRange:NSMakeRange(6, 2)];
    
    NSDateComponents *comps = [[NSDateComponents alloc]init];
    comps.year  = [year integerValue];
    comps.month = [month integerValue];
    comps.day   = [day integerValue];
    
    return comps;
}

+ (NSNumber *)numberFromComps:(NSDateComponents *)comps
{
    NSString *string = [NSString stringWithFormat:@"%ld%02ld%02ld", comps.year, comps.month, comps.day];
    return [NSNumber numberWithInt:[string intValue]];
}

+ (NSNumber *)getTodayYMD
{
    return [self numberFromComps:[self dateCompsFromDate:[self setSystemTimezone:[NSDate date]]]];
}

+ (NSNumber *)getYesterdayYMD
{
    return [self numberFromComps:[self dateCompsFromDate:[self setSystemTimezone:[NSDate dateWithTimeIntervalSinceNow:-24*60*60]]]];
}

+ (BOOL)isTodayByIndexPath:(NSIndexPath *)index
{
    if (index.section == 0 && index.row == 0) {
        return YES;
    }
    return NO;
}

+ (BOOL)isInTwodayByIndexPath:(NSIndexPath *)index
{
    if (index.section == 0 && (index.row == 0 || index.row == 1)) {
        return YES;
    }
    return NO;
}

+ (NSIndexPath *)getIndexPathFromDate:(NSNumber *)date
{
    // yyyymmddからindexPathを構築する
    NSDateComponents *targetComps = [self compsFromNumber:date];
    NSDateComponents *todayComps = [self dateCompsFromDate:nil];
    
    int section = 0;
    int row = 0;
    
    int yearDiff = todayComps.year - targetComps.year;
    section += 12 * yearDiff;
    int monthDiff = todayComps.month - targetComps.month;
    section += monthDiff;
    
    if (yearDiff == 0 && monthDiff == 0) {
        row = todayComps.day - targetComps.day;
    } else {
        row = [self getLastDay:targetComps] - targetComps.day;
    }
    
    return [NSIndexPath indexPathForRow:row inSection:section];
}

+ (int) getLastDay:(NSDateComponents *)comps
{
    // ひと月足して、日付を1日にしてから、1日引くと最終日をgetできる
    NSDateComponents *tmpComps = [self addDateComps:comps withUnit:@"month" withValue:1];
    tmpComps.day = 1;
    NSDateComponents *lastDayComps = [self addDateComps:tmpComps withUnit:@"day" withValue:-1];
    
    return lastDayComps.day;
}


@end
