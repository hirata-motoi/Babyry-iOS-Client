//
//  PartnerApply.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/09/16.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "PartnerApply.h"
#import "PartnerApplyEntity.h"
#import "Config.h"

@implementation PartnerApply

+ (BOOL) linkComplete
{
    PartnerApplyEntity *pae = [PartnerApplyEntity MR_findFirst];
    if (!pae.linkComplete) {
        return NO;
    } else {
        return YES;
    }
}

+ (void) setLinkComplete
{
    NSString *PartnerApplyEntityKeyName = [Config config][@"PartnerApplyEntityKeyName"];
    PartnerApplyEntity *pae = [PartnerApplyEntity MR_findFirstByAttribute:@"name" withValue:PartnerApplyEntityKeyName];
    if ([pae.linkComplete isEqual:[NSNumber numberWithBool:YES]]) {
        return;
    }
    
    if (pae) {
        pae.linkComplete = [NSNumber numberWithBool:YES];
    } else {
        PartnerApplyEntity *newPae = [PartnerApplyEntity MR_createEntity];
        newPae.linkComplete = [NSNumber numberWithBool:YES];
    }
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
}

+ (void) unsetLinkComplete
{
    NSString *PartnerApplyEntityKeyName = [Config config][@"PartnerApplyEntityKeyName"];
    PartnerApplyEntity *pae = [PartnerApplyEntity MR_findFirstByAttribute:@"name" withValue:PartnerApplyEntityKeyName];
    if ([pae.linkComplete isEqual:[NSNumber numberWithBool:NO]]) {
        return;
    }
    
    if (pae) {
        pae.linkComplete = [NSNumber numberWithBool:NO];
    } else {
        PartnerApplyEntity *newPae = [PartnerApplyEntity MR_createEntity];
        newPae.linkComplete = [NSNumber numberWithBool:NO];
    }
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
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
