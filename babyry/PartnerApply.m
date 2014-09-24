//
//  PartnerApply.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/09/16.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "PartnerApply.h"
#import "PartnerInviteEntity.h"
#import "Config.h"

@implementation PartnerApply

+ (BOOL) linkComplete
{
    PartnerInviteEntity *pie = [PartnerInviteEntity MR_findFirst];
    if (!pie.linkComplete) {
        return NO;
    } else {
        return YES;
    }
}

+ (void) setLinkComplete
{
    NSString *partnerInviteEntityKeyName = [Config config][@"PartnerInviteEntityKeyName"];
    PartnerInviteEntity *pie = [PartnerInviteEntity MR_findFirstByAttribute:@"name" withValue:partnerInviteEntityKeyName];
    if ([pie.linkComplete isEqual:[NSNumber numberWithBool:YES]]) {
        return;
    }
    
    if (pie) {
        pie.linkComplete = [NSNumber numberWithBool:YES];
    } else {
        PartnerInviteEntity *newPie = [PartnerInviteEntity MR_createEntity];
        newPie.linkComplete = [NSNumber numberWithBool:YES];
    }
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
}

+ (void) unsetLinkComplete
{
    NSString *partnerInviteEntityKeyName = [Config config][@"PartnerInviteEntityKeyName"];
    PartnerInviteEntity *pie = [PartnerInviteEntity MR_findFirstByAttribute:@"name" withValue:partnerInviteEntityKeyName];
    if ([pie.linkComplete isEqual:[NSNumber numberWithBool:NO]]) {
        return;
    }
    
    if (pie) {
        pie.linkComplete = [NSNumber numberWithBool:NO];
    } else {
        PartnerInviteEntity *newPie = [PartnerInviteEntity MR_createEntity];
        newPie.linkComplete = [NSNumber numberWithBool:NO];
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
