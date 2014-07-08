//
//  FamilyRole.m
//  babyry
//
//  Created by 平田基 on 2014/07/08.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "FamilyRole.h"

@implementation FamilyRole

+ (NSString *)selfRole
{
    PFQuery *query = [PFQuery queryWithClassName:@"FamilyRole"];
    query.cachePolicy = kPFCachePolicyCacheElseNetwork;
    [query whereKey:@"familyId" equalTo:[PFUser currentUser][@"familyId"]];
    PFObject *object = [query getFirstObject];
    return ([object[@"uploader"] isEqualToString:[PFUser currentUser][@"userId"]]) ? @"uploader" : @"chooser";
}

+ (void)updateCache
{
    PFQuery *query = [PFQuery queryWithClassName:@"FamilyRole"];
    query.cachePolicy = kPFCachePolicyNetworkOnly;
    [query whereKey:@"familyId" equalTo:[PFUser currentUser][@"familyId"]];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error){}];
    // nothing to return because this method is only for updating cache
}

- (void)createFamilyRole:(NSMutableDictionary *)data
{
    PFObject *object = [PFObject objectWithClassName:@"FamilyRole"];
    object[@"familyId"] = data[@"familyId"];
    object[@"uploader"] = data[@"uploader"];
    object[@"chooser"]  = data[@"chooser"];
    [object save];
}


- (NSString *)getSelfFamilyRole
{
    NSString *userId   = [PFUser currentUser][@"userId"];
    NSString *familyId = [PFUser currentUser][@"familyId"];
    
    PFQuery *query = [PFQuery queryWithClassName:@"FamilyRole"];
    [query whereKey:@"familyId" equalTo:familyId];
    PFObject *object = [query getFirstObject];
    return ([object[@"uploader"] isEqualToString:userId]) ? @"uploader" : @"chooser";
}

- (NSString *)getFamilyRoleWithFamilyId:(NSString *)familyId withUserId:(NSString *)userId
{
    PFQuery *query = [PFQuery queryWithClassName:@"FamilyRole"];
    [query whereKey:@"familyId" equalTo:familyId];
    PFObject *object = [query getFirstObject];
    return ([object[@"uploader"] isEqualToString:userId]) ? @"uploader" : @"chooser";
}

// 非同期でFamiyRoleをfetchして何か処理をする
- (void)fetchFamilyRoleWithBlock:(PFArrayResultBlock)block withFamilyId:(NSString *)familyId
{
    PFQuery *query = [PFQuery queryWithClassName:@"FamilyRole"];
    [query whereKey:@"familyId" equalTo:familyId];
    [query findObjectsInBackgroundWithBlock:block];
}

@end
