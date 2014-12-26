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

+ (NSMutableArray *)syncChildProperties
{
    PFUser *currentUser = [PFUser currentUser];
    if (!currentUser || !currentUser[@"familyId"] || [currentUser[@"familyId"] isEqualToString:@""]) {
        return nil;
    }
    // childを取得
    PFQuery *query = [PFQuery queryWithClassName:@"Child"];
    [query whereKey:@"familyId" equalTo:currentUser[@"familyId"]];
    NSArray *childList = [query findObjects];
    
    if (childList.count < 1) {
        return nil;
    }
   
    [self deleteUnavailableChildProperties:childList];
    [self saveChildProperties:childList];
    return [self getChildProperties];
}

+ (NSMutableDictionary *)syncChildProperty:(NSString *)childObjectId
{
    if (!childObjectId) {
        return nil;
    }
    PFQuery *query = [PFQuery queryWithClassName:@"Child"];
    [query whereKey:@"objectId" equalTo:childObjectId];
    NSArray *childList = [query findObjects];
    
    if (childList.count < 1) {
        return nil;
    }
    
    [self deleteUnavailableChildProperties:childList];
    [self saveChildProperties:childList];
    return [self getChildProperty:childObjectId];
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
    NSMutableArray *beforeSyncChildProperties = [self getChildProperties];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Child"];
    [query whereKey:@"familyId" equalTo:currentUser[@"familyId"]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Failed to get Child for asyncChildPropertiesWithBlock familyId:%@", currentUser[@"familyId"]]];
            return;
        }
        if (objects.count < 1) {
            [self deleteUnavailableChildProperties:nil];
            if (block) {
                block(beforeSyncChildProperties);
            }
            return;
        }
        
        [self deleteUnavailableChildProperties:objects];
        [self saveChildProperties:objects];
        if (block) {
            block(beforeSyncChildProperties);
        }
    }];
}

+ (NSMutableDictionary *)getChildProperty:(NSString *)childObjectId
{
    NSArray *childProperties = [self getChildProperties];
    for (NSMutableDictionary *childProperty in childProperties) {
        if ([childProperty[@"objectId"] isEqualToString:childObjectId]) {
            return childProperty;
        }
    }
    return nil;
}

+ (NSMutableArray *)getChildProperties
{
    NSArray *childPropertiesRecords = [ChildPropertyEntity MR_findAllSortedBy:@"createdAt" ascending:YES];
    NSMutableArray *childProperties = [[NSMutableArray alloc]init];
    for (ChildPropertyEntity *childPropertyRecord in childPropertiesRecords) {
        NSMutableDictionary *childProperty = [NSMutableDictionary dictionaryWithDictionary:[childPropertyRecord dictionaryWithValuesForKeys:[[[childPropertyRecord entity] attributesByName] allKeys]]];
        // valueがNULLになっているkeyは不要なので削除
        for (NSString *key in [childProperty allKeys]) {
            if (childProperty[key] == [NSNull null]) {
                [childProperty removeObjectForKey:key];
            }
        }
        [childProperties addObject:childProperty];
    }
    return childProperties;
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

+ (void)saveChildProperties:(NSArray *)childList
{
    NSArray *childProperties = [ChildPropertyEntity MR_findAll];
    for (PFObject *child in childList) {
        NSString *childObjectId = child.objectId;
        ChildPropertyEntity *childProperty = [self findChildProperty:childProperties withObjectId:childObjectId];
        if (!childProperty) {
            childProperty = [ChildPropertyEntity MR_createEntity];
        }
        
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
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
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
    for (NSString *key in [params allKeys]) {
        if (params[key] == [NSNull null]) {
            [childProperty setValue:nil forKey:key];
        } else {
            [childProperty setValue:params[key] forKey:key];
        }
    }
    
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

+ (BOOL)deleteByObjectId:(NSString *)objectId
{
    ChildPropertyEntity *childProperty = [self fetchChildProperty:objectId];
    if (!childProperty) {
        return NO;
    }
    
    [childProperty MR_deleteEntity];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    return YES;
}

+ (void)removeChildPropertiesFromCoreData
{
    NSArray *childProperties = [ChildPropertyEntity MR_findAll];
    for (ChildPropertyEntity *childProperty in childProperties) {
        [childProperty MR_deleteEntity];
    }
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
}

@end
