//
//  ChildIconManager.m
//  babyry
//
//  Created by hirata.motoi on 2015/01/06.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import "ChildIconManager.h"
#import "AWSCommon.h"
#import "Config.h"
#import "ImageCache.h"
#import "Logger.h"
#import "ChildProperties.h"
#import "AWSS3Utils.h"
#import "Config.h"
#import "ImageUtils.h"

@implementation ChildIconManager

// 行lockができず厳密なtransaction管理は難しいのでやらない
+ (void)updateChildIcon:(NSData *)imageData withChildObjectId:(NSString *)childObjectId
{
    if (!imageData || !childObjectId) {
        return;
    }
    
    // 古いアイコンは別名で保存  画像の保存に失敗したら古いアイコンに戻す
    [self copyOldIcon:childObjectId];
    // 新規アイコンを保存
    [ImageCache setCache:[Config config][@"ChildIconFileName"] image:imageData dir:childObjectId];
    
    
    PFQuery *query = [PFQuery queryWithClassName:@"Child"];
    [query whereKey:@"objectId" equalTo:childObjectId];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            [self resetIcon:childObjectId];
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Failed to find Child for ChildIcon childObjectId:%@ error:%@", childObjectId, error]];
            return;
        }
        
        if (objects.count < 1) {
            [self resetIcon:childObjectId];
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Child NOT FOUND for ChildIcon childObjectId:%@", childObjectId]];
            return;
        }
        
        PFObject *child = objects[0];
        NSNumber *iconVersionNumber = child[@"iconVersion"];
        NSInteger newIconVersion = (iconVersionNumber) ? [iconVersionNumber integerValue] + 1 : 1;
        
        [self saveToAWSWithData:imageData
                  withChildObjectId:childObjectId
                    withIconVersion:newIconVersion
                          withBlock:^{
                              // parseのレコードを更新
                              child[@"iconVersion"] = [NSNumber numberWithInteger:newIconVersion];
                              [child saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                  if (error) {
                                      [self resetIcon:childObjectId];
                                      [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Failed to save iconVersion childObjectId:%@ iconVersion:%ld error:%@", child[@"objectId"], (long)newIconVersion, error]];
                                      return;
                                  }
                                  // サムネイルのコピーを配置
                                  [ImageCache setCache:[Config config][@"ChildIconFileName"] image:imageData dir:childObjectId];
                                  [self removeOldIcon:childObjectId];
                                 
                                  // こども情報を更新
                                  NSMutableDictionary *params = [[NSMutableDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithInteger:newIconVersion], @"iconVersion", nil];
                                  [ChildProperties updateChildPropertyWithObjectId:childObjectId withParams:params];
                                  
                                  [[NSNotificationCenter defaultCenter] postNotificationName:@"childSwitchViewIconChanged" object:nil];
                              }];
                          }];
    }];
}

+ (void)saveToAWSWithData:(NSData *)imageData withChildObjectId:(NSString *)childObjectId withIconVersion:(NSInteger)iconVersion withBlock:(SaveToAWSBlock)block
{
    AWSServiceConfiguration *configuration = [AWSCommon getAWSServiceConfiguration:@"S3"];
    AWSS3PutObjectRequest *putRequest = [AWSS3PutObjectRequest new];
    putRequest.bucket = [Config config][@"AWSBucketName"];
    putRequest.key = [NSString stringWithFormat:@"Icon/%@/%ld", childObjectId, (long)iconVersion];
    putRequest.body = imageData;
    putRequest.contentLength = [NSNumber numberWithLong:[imageData length]];
    putRequest.contentType = [ImageUtils contentTypeForImageData:imageData];
    putRequest.cacheControl = @"no-cache";
    AWSS3 *awsS3 = [[AWSS3 new] initWithConfiguration:configuration];
    [[awsS3 putObject:putRequest] continueWithBlock:^id(BFTask *task) {
        if (task.error) {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in Saving child icon to S3 childObjectid:%@ iconVersion:%ld error:%@", childObjectId, iconVersion, task.error]];
            return nil;
        }
        block();
        return nil;
    }];
}

+ (void)syncChildIconsInBackground
{
    NSMutableArray *childProperties = [ChildProperties getChildProperties];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithInt:0], @"count", nil];
    for (NSMutableDictionary *childProperty in childProperties) {
        if (!childProperty[@"iconVersion"] || [childProperty[@"iconVersion"] integerValue] < 1) {
            return;
        }
        NSString *bucketKey = [NSString stringWithFormat:@"Icon/%@/%d", childProperty[@"objectId"], [childProperty[@"iconVersion"] intValue]];
        dic[@"count"] = [NSNumber numberWithInt:[dic[@"count"] intValue] + 1];
        [AWSS3Utils singleDownloadWithKey:bucketKey withBlock:^(NSMutableDictionary *params) {
            NSData *imageData = params[@"imageData"];
            
            if (imageData) {
                [ImageCache setCache:[Config config][@"ChildIconFileName"] image:imageData dir:childProperty[@"objectId"]];
            }
            
            dic[@"count"] = [NSNumber numberWithInt:[dic[@"count"] intValue] - 1];
            
            if ([dic[@"count"] intValue] < 1) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"childSwitchViewIconChanged" object:nil];
            }
        }];
    }
}

+ (void)copyOldIcon:(NSString *)childObjectId
{
    NSData *oldIconData = [ImageCache getCache:[Config config][@"ChildIconFileName"] dir:childObjectId];
    [ImageCache setCache:@"icon.bak" image:oldIconData dir:childObjectId];
}

+ (void)removeOldIcon:(NSString *)childObjectId
{
    [ImageCache removeCache:[NSString stringWithFormat:@"%@/icon.bak", childObjectId]];
}

+ (void)resetIcon:(NSString *)childObjectId
{
    NSData *oldIconData = [ImageCache getCache:@"icon.bak" dir:childObjectId];
    [ImageCache setCache:[Config config][@"ChildIconFileName"] image:oldIconData dir:childObjectId];
    [self removeOldIcon:childObjectId];
}

@end
