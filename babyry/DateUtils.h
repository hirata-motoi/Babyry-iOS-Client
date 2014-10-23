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
+(NSString *) getWeekStringFromNum:(int)weekDayNum;
+(NSDateComponents *)addDateComps:(NSDateComponents *)comps withUnit:(NSString *)unit withValue:(NSInteger)value;
+ (NSDateComponents *)dateCompsFromDate:(NSDate *)date;
+ (NSDateComponents *)compsFromNumber:(NSNumber *)date;
+ (NSNumber *)numberFromComps:(NSDateComponents *)comps;
+ (NSNumber *)getTodayYMD;
+ (NSNumber *)getYesterdayYMD;
+ (BOOL)isTodayByIndexPath:(NSIndexPath *)index;
+ (BOOL)isInTwodayByIndexPath:(NSIndexPath *)index;

@end
