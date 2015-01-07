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

@implementation ChildIconManager

// 行lockができず厳密なtransaction管理は難しいのでやらない
+ (void)updateChildIcon:(NSData *)imageData withChildObjectId:(NSString *)childObjectId
{
    if (!imageData || !childObjectId) {
        return;
    }
    
    PFQuery *query = [PFQuery queryWithClassName:@"Child"];
    [query whereKey:@"objectId" equalTo:childObjectId];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            // TODO error handling
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Failed to find Child for ChildIcon childObjectId:%@ error:%@", childObjectId, error]];
            return;
        }
        
        if (objects.count < 1) {
            // TODO error handling
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Child NOT FOUND for ChildIcon childObjectId:%@", childObjectId]];
            return;
        }
        
        PFObject *child = objects[0];
        NSNumber *iconVersionNumber = child[@"iconVersion"];
        NSInteger newIconVersion = (iconVersionNumber) ? [iconVersionNumber integerValue] + 1 : 1;
        
        [self saveToAWSWithFilePath:imageData
                  withChildObjectId:childObjectId
                    withIconVersion:newIconVersion
                          withBlock:^{
                              // parseのレコードを更新
                              child[@"iconVersion"] = [NSNumber numberWithInteger:newIconVersion];
                              [child saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                  if (error) {
                                      [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Failed to save iconVersion childObjectId:%@ iconVersion:%ld error:%@", child[@"objectId"], (long)newIconVersion, error]];
                                      return;
                                  }
                                  // サムネイルのコピーを配置
                                  [ImageCache setCache:[Config config][@"ChildIconFileName"] image:imageData dir:childObjectId];
                                 
                                  // こども情報を更新
                                  NSMutableDictionary *params = [[NSMutableDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithInteger:newIconVersion], @"iconVersion", nil];
                                  [ChildProperties updateChildPropertyWithObjectId:childObjectId withParams:params];
                                  
                                  
                                  [[NSNotificationCenter defaultCenter] postNotificationName:@"childSwitchViewIconChanged" object:nil];
                              }];
                          }];
    }];
}

+ (void)saveToAWSWithFilePath:(NSData *)imageData withChildObjectId:(NSString *)childObjectId withIconVersion:(NSInteger)iconVersion withBlock:(SaveToAWSBlock)block
{
    AWSServiceConfiguration *configuration = [AWSCommon getAWSServiceConfiguration:@"S3"];
    AWSS3PutObjectRequest *putRequest = [AWSS3PutObjectRequest new];
    putRequest.bucket = [Config config][@"AWSBucketName"];
    putRequest.key = [NSString stringWithFormat:@"Icon/%@/%ld", childObjectId, (long)iconVersion];
    putRequest.body = imageData;
    putRequest.contentLength = [NSNumber numberWithLong:[imageData length]];
    putRequest.contentType = [self contentTypeForImageData:imageData];
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

// あんまりやりたくないが・・
+ (NSString *)contentTypeForImageData:(NSData *)data {
    uint8_t c;
    [data getBytes:&c length:1];
    
    switch (c) {
        case 0xFF:
            return @"image/jpeg";
        case 0x89:
            return @"image/png";
        case 0x47:
            return @"image/gif";
        case 0x49:
        case 0x4D:
            return @"image/tiff";
    }
    return nil;
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
        [AWSS3Utils simpleDownloadWithKey:bucketKey WithBlock:^(NSMutableDictionary *params) {
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

@end