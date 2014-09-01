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
