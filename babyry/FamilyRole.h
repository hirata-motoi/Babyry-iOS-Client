//
//  FamilyRole.h
//  babyry
//
//  Created by 平田基 on 2014/07/08.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

typedef void (^UpdateFamilyRoleCacheBlock)();

@interface FamilyRole : NSObject


+ (PFObject *)getFamilyRole:(NSString *)cacheType;
+ (NSString *)selfRole:(NSString *)cacheType;
+ (void)updateCache;
+ (void)createFamilyRole: (NSMutableDictionary *)data;
+ (void)createFamilyRoleWithBlock:(NSMutableDictionary *)data withBlock:(PFBooleanResultBlock)block;
+ (void)fetchFamilyRole:(NSString *)familyId withBlock:(PFArrayResultBlock)block;
+ (void)switchRole:(NSString *)role;
+ (void) unlinkFamily:(PFBooleanResultBlock)block;
+ (void)updateFamilyRoleCacheWithBlock:(UpdateFamilyRoleCacheBlock)block;

@end
