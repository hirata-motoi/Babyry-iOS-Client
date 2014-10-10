//
//  ChildProperties.m
//  babyry
//
//  Created by hirata.motoi on 2014/10/08.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ChildProperties.h"
#import "ChildPropertyEntity.h"
#import "Logger.h"

@implementation ChildProperties

+ (void)syncChildProperties
{
    PFUser *currentUser = [PFUser currentUser];
    if (!currentUser || !currentUser[@"familyId"] || [currentUser[@"familyId"] isEqualToString:@""]) {
        return;
    }
    // childを取得
    PFQuery *query = [PFQuery queryWithClassName:@"Child"];
    [query whereKey:@"familyId" equalTo:currentUser[@"familyId"]];
    NSArray *childList = [query findObjects];
    
    if (childList.count < 1) {
        return;
    }
   
    NSMutableDictionary *oldestChildImageDate = [self getOldestChildImageDate:childList];
    [self deleteUnavailableChildProperties:childList];
    [self saveChildProperties:childList withOldestChildImageDate:oldestChildImageDate];
}

+ (void)asyncChildProperties
{
    [self asyncChildPropertiesWithBlock:nil];
}

+ (void)asyncChildPropertiesWithBlock:(UpdateChildPropertiesAsyncBlock)block
{
    PFUser *currentUser = [PFUser currentUser];
    if (!currentUser || !currentUser[@"familyId"] || [currentUser[@"familyId"] isEqualToString:@""]) {
        return;
    }
    
    PFQuery *query = [PFQuery queryWithClassName:@"Child"];
    [query whereKey:@"familyId" equalTo:currentUser[@"familyId"]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Failed to get Child for asyncChildPropertiesWithBlock familyId:%@", currentUser[@"familyId"]]];
            return;
        }
        if (objects.count < 1) {
            return;
        }
        
        NSMutableDictionary *oldestChildImageDate = [[NSMutableDictionary alloc]init];
        __block int queryCompletedCount = 0;
        for (PFObject *child in objects) {
            PFQuery *query = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%ld", [child[@"childImageShardIndex"] integerValue]]];
            [query whereKey:@"imageOf" equalTo:child.objectId];
            [query orderByAscending:@"date"];
            [query getFirstObjectInBackgroundWithBlock:^(PFObject *childImage, NSError *error) {
                if (childImage) {
                    oldestChildImageDate[childImage.objectId] = childImage[@"date"];
                }
                queryCompletedCount++;
                
                if (queryCompletedCount == objects.count) {
                    [self saveChildProperties:objects withOldestChildImageDate:oldestChildImageDate];
                    
                    if (block) {
                        block();
                    }
                }
            }];
        
        }
    }];
}

+ (NSMutableDictionary *)getChildProperty:(NSString *)childObjectId
{
    NSArray *childProperties = [self getChildProperties];
    for (NSMutableDictionary *childProperty in childProperties) {
        if ([childProperty[@"objectIs"] isEqualToString:childObjectId]) {
            return childProperty;
        }
    }
    return nil;
}

+ (NSMutableArray *)getChildProperties
{
    NSArray *childPropertiesRecords = [ChildPropertyEntity MR_findAll];
    NSMutableArray *childProperties = [[NSMutableArray alloc]init];
    for (ChildPropertyEntity *childPropertyRecord in childPropertiesRecords) {
        [childProperties addObject:[childPropertyRecord dictionaryWithValuesForKeys:[[[childPropertyRecord entity] attributesByName] allKeys]]];
    }
    return childProperties;
}

+ (NSMutableDictionary *)getOldestChildImageDate:(NSArray *)childList
{
    NSMutableDictionary *oldestChildImageDate = [[NSMutableDictionary alloc]init];
                         
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        for (PFObject *child in childList) {
            PFQuery *query = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%ld", [child[@"childImageShardIndex"] integerValue]]];
            [query whereKey:@"imageOf" equalTo:child.objectId];
            [query orderByAscending:@"date"];
            PFObject *oldestChildImage = [query getFirstObject];
            if (oldestChildImage) {
                oldestChildImageDate[child.objectId] = oldestChildImage[@"date"];
            }
        }
        dispatch_semaphore_signal(semaphore);
    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return oldestChildImageDate;
}
             
+ (ChildPropertyEntity *)findChildProperty:(NSArray *)childProperties withObjectId:(NSString *)childObjectId
{
    for (ChildPropertyEntity *childProperty in childProperties) {
        if ([childProperty.objectId isEqualToString:childObjectId]) {
            return childProperty;
        }
    }
    return nil;
}

+ (void)saveChildProperties:(NSArray *)childList withOldestChildImageDate:(NSMutableDictionary *)oldestChildImageDate
{
    NSArray *childProperties = [ChildPropertyEntity MR_findAll];
    for (PFObject *child in childList) {
        NSString *childObjectId = child.objectId;
        ChildPropertyEntity *childProperty = [self findChildProperty:childProperties withObjectId:childObjectId];
        if (!childProperty) {
            childProperty = [ChildPropertyEntity MR_createEntity];
        }
        
        NSLog(@"saveChildProperties child.createdBy:%@", child[@"createdBy"]);
        childProperty.objectId   = child.objectId;
        childProperty.updatedAt  = child.updatedAt;
        childProperty.createdAt  = child.createdAt;
        childProperty.createdBy  = [child[@"createdBy"] objectId];
        childProperty.name       = child[@"name"];
        childProperty.birthday   = child[@"birthday"];
        childProperty.sex        = child[@"sex"];
        childProperty.familyId             = child[@"familyId"];
        childProperty.childImageShardIndex = child[@"childImageShardIndex"];
        childProperty.commentShardIndex    = child[@"commentShardIndex"];
        childProperty.calendarStartDate    = child[@"calendarStartDate"];
        childProperty.oldestChildImageDate = oldestChildImageDate[child.objectId];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
        NSLog(@"saveChildProperties end childObjectId:%@", child.objectId);
    }
}

+ (ChildPropertyEntity *)fetchChildProperty:(NSString *)childObjectId
{
    return [ChildPropertyEntity MR_findFirstByAttribute:@"objectId" withValue:childObjectId];
}

+ (NSArray *)fetchChildProperties:(NSArray *)childObjectIds
{
    if (!childObjectIds) {
        return [ChildPropertyEntity MR_findAll];
    }
    
    NSPredicate *filter = [NSPredicate predicateWithFormat:@"objectId IN %@", childObjectIds];
    return [self fetchChildPropertiesWithPredicate:filter];
}

+ (NSArray *)fetchChildPropertiesWithPredicate:(NSPredicate *)predicate
{
    return [ChildPropertyEntity MR_findAllWithPredicate:predicate];
}

+ (void)updateChildPropertyWithObjectId:(NSString *)childObjectId withParams:(NSMutableDictionary *)params
{
    ChildPropertyEntity *childProperty = [self fetchChildProperty:childObjectId];
    [childProperty setValuesForKeysWithDictionary:params];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
}

+ (void)deleteUnavailableChildProperties:(NSArray *)childList
{
    NSMutableArray *childObjectIds = [[NSMutableArray alloc]init];
    for (ChildPropertyEntity *childProperty in childList) {
        [childObjectIds addObject:childProperty.objectId];
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT (objectId IN %@)", childObjectIds];
    NSArray *unavailableChildProperties = [self fetchChildPropertiesWithPredicate:predicate];
    for (ChildPropertyEntity *childProperty in unavailableChildProperties) {
        [childProperty MR_deleteEntity];
    }
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
}

@end
