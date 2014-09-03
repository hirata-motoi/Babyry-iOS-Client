//
//  FamilyRole.m
//  babyry
//
//  Created by 平田基 on 2014/07/08.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "FamilyRole.h"

@implementation FamilyRole

+ (PFObject *)getFamilyRole:(NSString *)cacheType
{
    PFQuery *query = [PFQuery queryWithClassName:@"FamilyRole"];
    if ([cacheType isEqualToString:@"noCache"]) {
        query.cachePolicy = kPFCachePolicyNetworkOnly;
    } else if ([cacheType isEqualToString:@"useCache"]) {
        query.cachePolicy = kPFCachePolicyCacheElseNetwork;
    } else if ([cacheType isEqualToString:@"NetworkFirst"]) {
        query.cachePolicy = kPFCachePolicyNetworkElseCache;
    } else if ([cacheType isEqualToString:@"cachekOnly"]) {
        query.cachePolicy = kPFCachePolicyCacheOnly;
    } else {
        query.cachePolicy = kPFCachePolicyCacheElseNetwork;
    }
    [query whereKey:@"familyId" equalTo:[PFUser currentUser][@"familyId"]];
    PFObject *object = [query getFirstObject];
    return object;
}

+ (NSString *)selfRole:(NSString *)cacheType
{
    PFObject *object = [self getFamilyRole:cacheType];
    if (object) {
        return ([object[@"uploader"] isEqualToString:[PFUser currentUser][@"userId"]]) ? @"uploader" : @"chooser";
    } else {
        return nil;
    }
}

+ (void)updateCache
{
    PFQuery *query = [PFQuery queryWithClassName:@"FamilyRole"];
    query.cachePolicy = kPFCachePolicyNetworkOnly;
    [query whereKey:@"familyId" equalTo:[PFUser currentUser][@"familyId"]];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error){}];
    // nothing to return because this method is only for updating cache
}

+ (void)createFamilyRole:(NSMutableDictionary *)data
{
    PFObject *object = [PFObject objectWithClassName:@"FamilyRole"];
    object[@"familyId"] = data[@"familyId"];
    object[@"uploader"] = data[@"uploader"];
    object[@"chooser"]  = data[@"chooser"];
    [object save];
}

+ (void)createFamilyRoleWithBlock:(NSMutableDictionary *)data withBlock:(PFBooleanResultBlock)block
{
    PFObject *object = [PFObject objectWithClassName:@"FamilyRole"];
    object[@"familyId"] = data[@"familyId"];
    object[@"uploader"] = data[@"uploader"];
    object[@"chooser"]  = data[@"chooser"];
    [object saveInBackgroundWithBlock:block];
}

+ (void)fetchFamilyRole:(NSString *)familyId withBlock:(PFArrayResultBlock)block
{
    PFQuery *query = [PFQuery queryWithClassName:@"FamilyRole"];
    [query whereKey:@"familyId" equalTo:familyId];
    [query findObjectsInBackgroundWithBlock:block];
}

@end
