//
//  PartnerApply.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/09/16.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "PartnerApply.h"
#import "PartnerInviteEntity.h"
#import "PartnerInvitedEntity.h"
#import "Config.h"
#import "PushNotification.h"
#import "Logger.h"

@implementation PartnerApply

+ (BOOL) linkComplete
{
    PartnerInviteEntity *pie = [PartnerInviteEntity MR_findFirst];
    if (!pie || !pie.linkComplete || [pie.linkComplete isEqual:[NSNumber numberWithBool:NO]]) {
        return NO;
    } else {
        return YES;
    }
}

+ (void) setLinkComplete
{
    PartnerInviteEntity *pie = [PartnerInviteEntity MR_findFirst];
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
    PartnerInviteEntity *pie = [PartnerInviteEntity MR_findFirst];
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

+ (void) registerApplyList
{
    // pinコード入力している場合(CoreDataにデータがある場合)、PartnerApplyListにレコードを入れる
    PartnerInvitedEntity *pie = [PartnerInvitedEntity MR_findFirst];
    if (pie.familyId) {
        // PartnerApplyListにレコードを突っ込む
        PFObject *object = [PFObject objectWithClassName:@"PartnerApplyList"];
        object[@"familyId"] = pie.familyId;
        object[@"applyingUserId"] = [PFUser currentUser][@"userId"];
        [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
            if (succeeded) {
                // 保存に成功したらpush通知送る
                PFQuery *partner = [PFQuery queryWithClassName:@"_User"];
                [partner whereKey:@"familyId" equalTo:pie.familyId];
                [partner findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
                    if (objects) {
                        for (PFObject *object in objects) {
                            NSMutableDictionary *options = [[NSMutableDictionary alloc]init];
                            options[@"formatArgs"] = [PFUser currentUser][@"nickName"];
                            NSMutableDictionary *data = [[NSMutableDictionary alloc]init];
                            options[@"data"] = data;
                            if (![object[@"userId"] isEqualToString:[PFUser currentUser][@"userId"]]) {
                                [PushNotification sendToSpecificUserInBackground:@"receiveApply" withOptions:options targetUserId:object[@"userId"]];
                            }
                        }
                    }
                }];
            }
        }];
    }
}

+ (void) removeApplyListWithBlock:(RemovePartnerApplyBlock)block
{
    PartnerInvitedEntity *pie = [PartnerInvitedEntity MR_findFirst];
    if (pie.familyId) {
        PFQuery *apply = [PFQuery queryWithClassName:@"PartnerApplyList"];
        [apply whereKey:@"familyId" equalTo:pie.familyId];
        [apply findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
            if ([objects count] > 0) {
                for (PFObject *object in objects) {
                    [object deleteInBackground];
                }
            }
            [self removePartnerInvitedFromCoreData];
        }];
    }
}

+ (void)removePartnerInvitedFromCoreData
{
    NSArray *rows = [PartnerInvitedEntity MR_findAll];
    for (PartnerInvitedEntity *row in rows) {
        [row MR_deleteEntity];
    }
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
}

+ (void)removePartnerInviteFromCoreData
{
    NSArray *rows = [PartnerInviteEntity MR_findAll];
    for (PartnerInviteEntity *row in rows) {
        [row MR_deleteEntity];
    }
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
}

// PartnerApplyListの情報をPartnerInvitedEntityへsync
// PIN CODEは不要なのでsyncしない(というかParse上にデータがないのでできない)
+ (void)syncPartnerApply
{
    if (![PFUser currentUser][@"familyId"]) {
        return;
    }
    
    PFQuery *query = [PFQuery queryWithClassName:@"PartnerApplyList"];
    [query whereKey:@"applyingUserId" equalTo:[PFUser currentUser][@"userId"]];
    [query orderByDescending:@"createdAt"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Failed to load PartnerApplyList error:%@", error]];
            return;
        }
        if (objects.count < 1) {
            NSArray *rows = [PartnerInvitedEntity MR_findAll];
            for (PartnerInvitedEntity *row in rows) {
                [row MR_deleteEntity];
            }
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
            return;
        }
        
        PartnerInvitedEntity *row = [PartnerInvitedEntity MR_findFirst];
        if (!row) {
            row = [PartnerInvitedEntity MR_createEntity];
        }
        row.familyId = objects[0][@"familyId"]; // 申請相手のfamilyId
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    }];
}

+ (void)checkPartnerApplyListWithBlock:(CheckPartnerApplyBlock)block
{
    PartnerInvitedEntity *pie = [PartnerInvitedEntity MR_findFirst];
    PFQuery *query = [PFQuery queryWithClassName:@"PartnerApplyList"];
    [query whereKey:@"familyId" equalTo:pie.familyId];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Failed to load PartnerApplyList familyId:%@ error:%@", pie.familyId, error]];
            return;
        }
        block(objects.count > 0);
    }];
}

@end
