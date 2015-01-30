//
//  Comment.m
//  babyry
//
//  Created by Kenji Suzuki on 2015/01/18.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import "Comment.h"
#import "CommentNumEntity.h"
#import "ChildProperties.h"
#import "Logger.h"
#import <AFNetworking.h>
#import "Config.h"

// クラス変数
static BOOL updatingCommentEntity = NO;

@implementation Comment

+ (NSMutableDictionary *)getAllCommentNum
{
    NSArray *commentNumEntities = [CommentNumEntity MR_findAll];
    NSMutableDictionary *commentNumDic = [[NSMutableDictionary alloc] init];
    for (CommentNumEntity *commentNumEntity in commentNumEntities) {
        commentNumDic[commentNumEntity.key] = commentNumEntity.value;
    }
    return commentNumDic;
}

+ (void) updateCommentNumEntity
{
    if (updatingCommentEntity) {
        return;
    }
    updatingCommentEntity = YES;
    
    NSMutableArray *childIds = [[NSMutableArray alloc] init];
    NSMutableArray *childProperties = [ChildProperties getChildProperties];
    for (NSMutableDictionary *childProperty in childProperties) {
        [childIds addObject:childProperty[@"objectId"]];
    }
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary* param = @{@"childId" : childIds};
    [manager GET:[NSString stringWithFormat:@"%@/comment_get", [Config config][@"CloudCodeURL"]]
      parameters:param
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             if (responseObject[@"success"]) {
                [self updateCommentNumWithDate:responseObject[@"success"]];
             } else {
                [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error API response in getComment by childIds, %@", responseObject[@"error"]]];
             }
             updatingCommentEntity = NO;
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error){
             [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error HTTP connect in getComment by childIds, %@", error]];
             updatingCommentEntity = NO;
         }];
}

+ (void)updateCommentNumWithDate:(NSDictionary *)commentNums
{
    NSArray *commentNumEntities = [CommentNumEntity MR_findAll];
    NSMutableDictionary *commentNumEntitiesDic = [[NSMutableDictionary alloc] init];
    for (CommentNumEntity *commentNumEntity in commentNumEntities) {
        commentNumEntitiesDic[commentNumEntity.key] = commentNumEntity;
    }
    
    for (NSString *key in [commentNums keyEnumerator]) {
        if (commentNumEntitiesDic[key]) {
            CommentNumEntity *existCommentNumEntity = commentNumEntitiesDic[key];
            existCommentNumEntity.value = [NSNumber numberWithInt:[commentNums[key] intValue]];
        } else {
            CommentNumEntity *newCommentNumEntity = [CommentNumEntity MR_createEntity];
            newCommentNumEntity.key = key;
            newCommentNumEntity.value = [NSNumber numberWithInt:[commentNums[key] intValue]];
        }
    }
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
}

@end
