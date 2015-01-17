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

+(UIColor *) getPositiveColor
{
    return [UIColor_Hex colorWithHexString:@"45A1CE" alpha:1.0];
}

+(UIColor *)getNegativeColor
{
    return [UIColor colorWithRed:(float)126/256 green:(float)125/256 blue:(float)122/256 alpha:1.0];
}

+(UIColor *)getCalenderNumberColor
{
    return [UIColor_Hex colorWithHexString:@"1a1a1a" alpha:1.0];
}

+(UIColor *)getBlurTintColor
{
    return [UIColor_Hex colorWithHexString:@"e7e4d6" alpha:0.4];
}

+(UIColor *)getGlobalMenuSectionHeaderColor
{
    return [UIColor_Hex colorWithHexString:@"bfb488" alpha:1.0];
}

+(UIColor *)getGlobalMenuPartSwitchColor
{
    return [UIColor_Hex colorWithHexString:@"525e64" alpha:1.0];
}

+(UIColor *)getGlobalMenuLightGrayColor
{
    return [UIColor_Hex colorWithHexString:@"f1f1f1" alpha:1.0];
}

+(UIColor *)getGlobalMenuDarkGrayColor
{
    return [UIColor_Hex colorWithHexString:@"e6e6e6" alpha:1.0];
}

+(UIColor *)getLightPositiveColor
{
    return [UIColor colorWithRed:(float)144/256 green:(float)203/256 blue:(float)230/256 alpha:1.0];
}

@end
