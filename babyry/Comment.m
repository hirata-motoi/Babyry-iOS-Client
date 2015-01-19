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
#import "ChildPropertyEntity.h"

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

+ (void) updateCommentNumEntity:(NSString *)childObjectId
{
    if (updatingCommentEntity) {
        return;
    }
    updatingCommentEntity = YES;
    
    NSArray *commentNumEntities = [CommentNumEntity MR_findAll];
    NSMutableDictionary *commentNumEntitiesDic = [[NSMutableDictionary alloc] init];
    for (CommentNumEntity *commentNumEntity in commentNumEntities) {
        commentNumEntitiesDic[commentNumEntity.key] = commentNumEntity;
    }
    
    NSMutableDictionary *childProperty = [ChildProperties getChildProperty:childObjectId];
    NSString *className = [NSString stringWithFormat:@"Comment%ld", (long)[childProperty[@"commentShardIndex"] integerValue]];
    PFQuery *query = [PFQuery queryWithClassName:className];
    [query whereKey:@"childId" equalTo:childObjectId];
    [query orderByAscending:@"createdAt"];
    if (childProperty[@"lastCommentLoadedAt"]) {
        [query whereKey:@"createdAt" greaterThan:childProperty[@"lastCommentLoadedAt"]];
    }
    query.limit = 1000;
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if (error) {
            updatingCommentEntity = NO;
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in get Comment of %@ : %@", childObjectId, error]];
            return;
        }
        if (objects.count > 0) {
            NSMutableDictionary *commentNumForDate = [[NSMutableDictionary alloc] init];
            for (PFObject *object in objects) {
                if (!commentNumForDate[object[@"date"]]) {
                    commentNumForDate[object[@"date"]] = [NSNumber numberWithInt:1];
                } else {
                    int currentNum = [commentNumForDate[object[@"date"]] intValue];
                    commentNumForDate[object[@"date"]] = [NSNumber numberWithInt:currentNum+1];
                }
            }
            for (NSString *keyDate in commentNumForDate) {
                [self updateCommentNumWithDate:[NSNumber numberWithInt:[keyDate intValue]] childObjectId:childObjectId currentComments:commentNumEntitiesDic newCommentNum:[commentNumForDate[keyDate] intValue]];
            }
            PFObject *lastObject = objects.lastObject;
            NSMutableDictionary *updatedTmp = [[NSMutableDictionary alloc] init];
            updatedTmp[@"lastCommentLoadedAt"] = lastObject.createdAt;
            [ChildProperties updateChildPropertyWithObjectId:childObjectId withParams:updatedTmp];
        }
        updatingCommentEntity = NO;
    }];
}

+ (void)updateCommentNumWithDate:(NSNumber *)date childObjectId:(NSString *)childObjectId currentComments:(NSDictionary *)commentNumEntities newCommentNum:(int)newCommentNum
{
    NSString *key = [NSString stringWithFormat:@"%@%@", childObjectId, date];
    if (commentNumEntities[key]) {
        CommentNumEntity *commentNumEntity = commentNumEntities[key];
        int currentCommentNum = [commentNumEntity.value intValue];
        commentNumEntity.value = [NSNumber numberWithInt:(currentCommentNum + newCommentNum)];
    } else {
        CommentNumEntity *commentNumEntity = [CommentNumEntity MR_createEntity];
        commentNumEntity.key = key;
        commentNumEntity.value = [NSNumber numberWithInt:newCommentNum];
    }
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
}

@end
