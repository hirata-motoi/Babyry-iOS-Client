//
//  ColorUtils.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/08/12.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ColorUtils : NSObject

+(UIColor *) getSunDayCalColor;

+(UIColor *) getSatDayCalColor;

+(UIColor *) getWeekDayCalColor;

+(UIColor *) getBackgroundColor;

+(UIColor *) getSectionHeaderColor;

+(UIColor *) getCellBackgroundDefaultColor;

+(UIColor *) getBabyryColor;

+(UIColor *) getLoginViewBackColor;

+(UIColor *)getPastelRedColor;

+(UIColor *)getPositiveButtonColor;
+(UIColor *)getNegativeButtonColor;
+(UIColor *)getOtherButtonColor;
+(UIColor *)getFacebookButtonColor;

+(UIColor *)getIntroDarkGrayStringColor;
+(UIColor *)getLoginTextFieldPaceHolderColor;

@end
