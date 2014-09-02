//
//  Child.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/09/01.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "Child.h"
#import "Logger.h"

@implementation Child

+(void)deleteByFamilyId:(NSString *)familyId
{
    PFQuery *query = [PFQuery queryWithClassName:@"Child"];
    query.cachePolicy = kPFCachePolicyNetworkOnly;
    [query whereKey:@"familyId" equalTo:familyId];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error){
        if (error) {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in get child at deleteByFamilyId : %@", error]];
            return;
        }
        
        [object deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
            if (error) {
                [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in delete Child : %@", error]];
            }
        }];
    }];
}

@end
