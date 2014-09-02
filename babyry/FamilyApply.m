//
//  FamilyApply.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/09/01.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "FamilyApply.h"
#import "Logger.h"

@implementation FamilyApply

+ (PFObject *)getFamilyApply
{
    PFQuery *query = [PFQuery queryWithClassName:@"FamilyApply"];
    query.cachePolicy = kPFCachePolicyCacheElseNetwork;
    [query whereKey:@"userId" equalTo:[PFUser currentUser][@"userId"]];
    PFObject *object = [query getFirstObject];
    return object;
}

+ (NSString *)selfRole
{
    PFObject *object = [self getFamilyApply];
    if (object) {
        return object[@"role"];
    } else {
        return nil;
    }
}

+ (void)getApplyingEmailWithBlock:(GetApplyingEmailBlock)block
{
    PFQuery *query1 = [PFQuery queryWithClassName:@"FamilyApply"];
    query1.cachePolicy = kPFCachePolicyNetworkOnly;
    [query1 whereKey:@"userId" equalTo:[PFUser currentUser][@"userId"]];
    [query1 getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error){
        if (error) {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in get familyappylist at getApplyingEmailWithBlock : %@", error]];
            return;
        }
        NSString *inviteeUserId = [[NSString alloc] initWithString:object[@"inviteeUserId"]];
        
        PFQuery *query2 = [PFQuery queryWithClassName:@"_User"];
        query2.cachePolicy = kPFCachePolicyNetworkOnly;
        [query2 whereKey:@"userId" equalTo:inviteeUserId];
        [query2 getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error){
            if (error) {
                [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in get getApplyingEmailWithBlock at  : %@", error]];
                return;
            }

            block(object[@"emailCommon"]);
        }];
    }];
}

+ (void)deleteApply
{
    PFQuery *query = [PFQuery queryWithClassName:@"FamilyApply"];
    query.cachePolicy = kPFCachePolicyNetworkOnly;
    [query whereKey:@"userId" equalTo:[PFUser currentUser][@"userId"]];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error){
        if (error) {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in get familyappylist at delete Apply : %@", error]];
            return;
        }
        
        [object deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
            if (error) {
                [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in delete Apply : %@", error]];
            }
        }];
    }];
}

@end
