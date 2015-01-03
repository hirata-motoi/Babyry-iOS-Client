//
//  ImageDownloadInBackground.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/12/10.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ImageDownloadInBackground.h"
#import "ChildProperties.h"
#import "DateUtils.h"
#import "ImageCache.h"
#import "AWSS3Utils.h"
#import "AWSCommon.h"

@implementation ImageDownloadInBackground

- (void) downloadByPushInBackground:(NSNumber *)date childObjectId:(NSString *)childObjectId preSignedURLs:(NSArray *)preSignedURLs
{
    // pushを受けたらバックグラウンドで画像をダウンロードするメソッド
    // ダウンロードに時間かかる&pushの度によばれるのでインスタンスメソッドにする
    
    if ([date isEqual:[DateUtils getTodayYMD]] || [date isEqual:[DateUtils getYesterdayYMD]]) {
        // 今日昨日ならcandidateに突っ込む
        
    } else {
        NSLog(@"download!");
        // それ以外ならbestshotなのでbestshot用のキャッシュを作る
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfiguration:@"BackgroundSessionConfiguration"];
        configuration.allowsCellularAccess = YES;
        NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
        NSURL *assetURL = [NSURL URLWithString:preSignedURLs[0]];
        NSURLSessionDownloadTask *task = [session downloadTaskWithURL:assetURL];
        [task resume];
    }
    
    /*
    NSMutableDictionary *child = [ChildProperties getChildProperty:childObjectId];
    PFQuery *query = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%ld", (long)[child[@"childImageShardIndex"] integerValue]]];
    query.limit = 1000;
    [query whereKey:@"imageOf" equalTo:childObjectId];
    [query whereKey:@"date" equalTo:date];
    [query whereKey:@"bestFlag" notEqualTo:@"removed"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if (!error) {
            NSMutableArray *cacheSetQueueArray = [[NSMutableArray alloc] init];
            // candidate用
            if ([date isEqual:[DateUtils getTodayYMD]] || [date isEqual:[DateUtils getYesterdayYMD]]) {
                for (PFObject *object in objects) {
                    NSString *thumbPath = [NSString stringWithFormat:@"%@/candidate/%@/thumbnail/%@", childObjectId, [date stringValue], object.objectId];
                    if ([object.updatedAt timeIntervalSinceDate:[ImageCache returnTimestamp:thumbPath]] > 0) {

                        NSMutableDictionary *queueForCache = [[NSMutableDictionary alloc]init];
                        queueForCache[@"objectId"] = object.objectId;
                        queueForCache[@"childObjectId"] = childObjectId;
                        queueForCache[@"date"] = date;
                        queueForCache[@"imageType"] = @"candidate";

                        [cacheSetQueueArray addObject:queueForCache];
                    }
                }
            }

            // bestshot用
            for (PFObject *object in objects) {
                if ([object[@"bestFlag"] isEqualToString:@"choosed"]) {
                    NSString *thumbPath = [NSString stringWithFormat:@"%@/bestShot/thumbnail/%@", childObjectId, [date stringValue]];
                    if ([object.updatedAt timeIntervalSinceDate:[ImageCache returnTimestamp:thumbPath]] > 0) {

                        NSMutableDictionary *queueForCache = [[NSMutableDictionary alloc]init];
                        queueForCache[@"objectId"] = object.objectId;
                        queueForCache[@"childObjectId"] = childObjectId;
                        queueForCache[@"date"] = date;
                        if ([date isEqual:[DateUtils getTodayYMD]] || [date isEqual:[DateUtils getYesterdayYMD]]) {
                            queueForCache[@"imageType"] = @"fullsize";
                        }

                        [cacheSetQueueArray addObject:queueForCache];
                    }
                }
            }
            AWSS3Utils *awsS3Utils = [[AWSS3Utils alloc] init];
            [awsS3Utils makeCacheFromS3:cacheSetQueueArray configuration:[AWSCommon getAWSServiceConfiguration:@"S3"] withBlock:^(void){
                // 特に何もしない
            }];
        }
    }];
    */
}

- (void) URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    NSLog(@"didFinishDownloadingToURL %@", location);
}

@end
