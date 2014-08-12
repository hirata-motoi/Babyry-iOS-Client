//
//  ColorUtils.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/08/12.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ColorUtils.h"

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
    return [UIColor colorWithRed:0.949 green:0.789 blue:0.152 alpha:1.0];
}

+(UIColor *) getBackgroundColor
{
    return [UIColor colorWithRed:0.902 green:0.891 blue:0.836 alpha:1.0];
}

@end