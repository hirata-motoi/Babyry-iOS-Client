//
//  PartnerApply.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/09/16.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "PartnerApply.h"

@implementation PartnerApply

+ (NSString *) getApplyStatus
{
    return @"NoApplying";
}

+ (NSNumber *) issuePinCode
{
    int digit = 6;
    NSString *numbers = @"0123456789";
    NSString *topDigit = @"123456789";
    NSMutableString *pinCode = [NSMutableString stringWithCapacity:digit];
    
    for (int i = 0; i < digit; i++) {
        if (i == 0) {
            // topの桁は0にすると何かと嫌らしいので
            [pinCode appendFormat:@"%C", [topDigit characterAtIndex:arc4random() % [topDigit length]]];
        } else {
            [pinCode appendFormat:@"%C", [numbers characterAtIndex:arc4random() % [numbers length]]];
        }
    }
    return [NSNumber numberWithInt:[pinCode intValue]];
}

@end
