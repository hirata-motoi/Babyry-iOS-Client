//
//  AWSS3Utils.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/12/05.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "AWSS3Utils.h"
#import "ImageCache.h"
#import "Config.h"
#import "ChildProperties.h"
#import "Logger.h"
#import "AWSCommon.h"
#import "ImageUtils.h"

@implementation AWSS3Utils

- (void)makeCacheFromS3:(NSMutableArray *)downloadQueue configuration:(AWSServiceConfiguration *)configuration withBlock:(makeCacheFromS3Block)block
{
    if ([downloadQueue count] == 0) {
        block();
    }
    
    // queueのなかの重複をまとめる
    NSMutableArray *uniqDownloadQueue = [[NSMutableArray alloc] init];
    for (NSMutableDictionary *queue in downloadQueue) {
        if ([uniqDownloadQueue count] == 0) {
            [uniqDownloadQueue addObject:queue];
        } else {
            BOOL duplicateId = NO;
            for (NSMutableDictionary *uniqQueue in uniqDownloadQueue) {
                if ([uniqQueue[@"objectId"] isEqualToString:queue[@"objectId"]]) {
                    duplicateId = YES;
                    for (NSString *key in queue) {
                        uniqQueue[key] = queue[key];
                    }
                    break;
                }
            }
            if (!duplicateId) {
                [uniqDownloadQueue addObject:queue];
            }
        }
    }

    AWSS3TransferManager *transferManager = [[AWSS3TransferManager alloc] initWithConfiguration:configuration identifier:@"S3"];
    
    int __block executedCount = 0;
    for (NSMutableDictionary *queue in uniqDownloadQueue) {
        NSMutableDictionary *childProperty = [ChildProperties getChildProperty:queue[@"childObjectId"]];
        
        AWSS3TransferManagerDownloadRequest *downloadRequest = [AWSS3TransferManagerDownloadRequest new];
        downloadRequest.bucket = [Config config][@"AWSBucketName"];
        downloadRequest.key = [NSString stringWithFormat:@"%@/%@", [NSString stringWithFormat:@"ChildImage%ld", (long)[childProperty[@"childImageShardIndex"] integerValue]], queue[@"objectId"]];
        downloadRequest.responseCacheControl = @"no-cache";
        [[transferManager download:downloadRequest] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
            if (task.error){
                if ([task.error.domain isEqualToString:AWSS3TransferManagerErrorDomain]) {
                    switch (task.error.code) {
                        case AWSS3TransferManagerErrorCancelled:
                            break;
                        case AWSS3TransferManagerErrorPaused:
                            break;
                        default:
                            break;
                    }
                } else {
                    [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in makeCacheFromS3 : %@", task.error]];
                }
            }
            if (task.result) {
                AWSS3TransferManagerDownloadOutput *downloadOutput = task.result;
                //File downloaded successfully.
                
                NSData *downloadData = [NSData dataWithContentsOfURL:downloadOutput.body];
                UIImage *downloadImage = [ImageCache makeThumbNail:[UIImage imageWithData:downloadData]];
                if (queue[@"isFullSize"]) {
                    [ImageCache setCache:[queue[@"date"] stringValue]
                                   image:downloadData
                                     dir:[NSString stringWithFormat:@"%@/bestShot/fullsize", queue[@"childObjectId"]]
                     ];
                }
                if (queue[@"isBS"]) {
                    [ImageCache setCache:[queue[@"date"] stringValue]
                                   image:UIImageJPEGRepresentation(downloadImage, 0.7f)
                                     dir:[NSString stringWithFormat:@"%@/bestShot/thumbnail", queue[@"childObjectId"]]
                     ];
                }
                if (queue[@"isCandidate"]) {
                    [ImageCache setCache:queue[@"objectId"]
                                   image:UIImageJPEGRepresentation(downloadImage, 0.7f)
                                     dir:[NSString stringWithFormat:@"%@/candidate/%@/thumbnail", queue[@"childObjectId"], queue[@"date"]]
                     ];
                    [ImageCache setCache:queue[@"objectId"]
                                   image:downloadData
                                     dir:[NSString stringWithFormat:@"%@/candidate/%@/fullsize", queue[@"childObjectId"], queue[@"date"]]
                     ];
                }
                [ImageCache removeCache:[NSString stringWithFormat:@"%@/candidate/%@/thumbnail/%@-tmp", queue[@"childObjectId"], queue[@"date"], queue[@"objectId"]]];
            }
            
            // エラーも含め全てのキューが終わったらblockを返す
            // エラーになった物はキャッシュがセットされていないので画像が表示されないだけ(もう一度やって成功すれば表示される)
            executedCount++;
            if (executedCount == [uniqDownloadQueue count]) {
                block();
            }
            return nil;
        }];
    }
}

+ (void)singleDownloadWithKey:(NSString *)key withBlock:(SimpleDownloadBlock)block
{
    AWSS3TransferManager *transferManager = [[AWSS3TransferManager alloc] initWithConfiguration:[AWSCommon getAWSServiceConfiguration:@"S3"] identifier:@"S3"];
    AWSS3TransferManagerDownloadRequest *downloadRequest = [AWSS3TransferManagerDownloadRequest new];
    downloadRequest.bucket = [Config config][@"AWSBucketName"];
    downloadRequest.key = key;
    downloadRequest.downloadingFileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[key stringByReplacingOccurrencesOfString:@"/" withString:@"_"]]];
    downloadRequest.responseCacheControl = @"no-cache";
    
    [[transferManager download:downloadRequest] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
        NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
        if (task.error){
            if ([task.error.domain isEqualToString:AWSS3TransferManagerErrorDomain]) {
                switch (task.error.code) {
                    case AWSS3TransferManagerErrorCancelled:
                        break;
                    case AWSS3TransferManagerErrorPaused:
                        break;
                    default:
                        break;
                }
            } else {
                [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Failed to load image for simpleDownloadWithKey key:%@ error:%@", key, task.error]];
            }
        }
        if (task.result) {
            AWSS3TransferManagerDownloadOutput *downloadOutput = task.result;
            NSData *downloadData = [NSData dataWithContentsOfURL:downloadOutput.body];
            params[@"imageData"] = downloadData;
        }
        block(params);
        return nil;
    }];
}

-(NSString *) getS3PreSignedURL:(NSString *)bucket key:(NSString *)key configuration:(AWSServiceConfiguration *)configuration
{
    AWSS3PreSignedURLBuilder *urlBuilder = [[AWSS3PreSignedURLBuilder alloc] initWithConfiguration:configuration];
    AWSS3GetPreSignedURLRequest *getPreSignedURLRequest = [AWSS3GetPreSignedURLRequest new];
    getPreSignedURLRequest.bucket = bucket;
    getPreSignedURLRequest.key = key;
    getPreSignedURLRequest.HTTPMethod = AWSHTTPMethodGET;
    getPreSignedURLRequest.expires = [NSDate dateWithTimeIntervalSinceNow:10*60];
    BFTask *urlTask = [urlBuilder getPreSignedURL:getPreSignedURLRequest];
    if (urlTask.error) {
        return nil;
    } else {
        return urlTask.result;
    }
}

@end
