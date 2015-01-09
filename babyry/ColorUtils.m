//
//  ColorUtils.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/08/12.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ColorUtils.h"
#import "UIColor+Hex.h"

@implementation ColorUtils

+(UIColor *) getSunDayCalColor
{
    return [UIColor colorWithRed:0.949 green:0.574 blue:0.472 alpha:1.0];
}

+(UIColor *) getSatDayCalColor
{
    return [UIColor colorWithRed:0.484 green:0.769 blue:0.902 alpha:1.0];
}

+(UIColor *) getWeekDayCalColor
{
    return [self getBabyryColor];
}

+(UIColor *) getBackgroundColor
{
    return [UIColor colorWithRed:0.902 green:0.891 blue:0.836 alpha:1.0];
}

+(UIColor *) getSectionHeaderColor
{
    return [UIColor_Hex colorWithHexString:@"5C4300" alpha:0.9];
}

+(UIColor *) getCellBackgroundDefaultColor
{
    return [UIColor_Hex colorWithHexString:@"e7e4d6" alpha:1.0];
}

+(UIColor *) getBabyryColor
{
    return [UIColor_Hex colorWithHexString:@"f4c510" alpha:1.0];
}

+(UIColor *) getLoginViewBackColor
{
    return [UIColor colorWithRed:(float)245/256 green:(float)226/256 blue:(float)151/256 alpha:1.0];
}

+(UIColor *)getPastelRedColor
{
    return [UIColor_Hex colorWithHexString:@"ff77a1" alpha:1.0];
}

+(UIColor *)getPositiveButtonColor
{
    return [UIColor_Hex colorWithHexString:@"45a1ce" alpha:1.0];
}

+(UIColor *)getNegativeButtonColor
{
    return [UIColor_Hex colorWithHexString:@"7e7d7a" alpha:1.0];
}

+(UIColor *)getOtherButtonColor
{
    return [UIColor_Hex colorWithHexString:@"9d7300" alpha:1.0];
}

+(UIColor *)getFacebookButtonColor
{
    return [UIColor_Hex colorWithHexString:@"3b5998" alpha:1.0];
}

@end