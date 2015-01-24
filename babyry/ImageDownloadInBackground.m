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
#import "Config.h"

@implementation ImageDownloadInBackground
{
    int taskQueueCount;
}

- (id) init {
	self = [super init];
	if (self != nil) {
        _completionHandlerArray = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void) downloadByPushInBackground:(NSDictionary *)transitionInfo
{
    // preSignedURLを取得
    AWSServiceConfiguration *configuration = [AWSCommon getAWSServiceConfiguration:@"S3"];
    AWSS3Utils *awsS3Utils = [[AWSS3Utils alloc] init];
    
    NSMutableArray *preSignedURLs = [[NSMutableArray alloc] init];
    for (NSString *imageId in transitionInfo[@"imageIds"]) {
        NSString *key = [NSString stringWithFormat:@"%@/%@", transitionInfo[@"dirName"], imageId];
        NSString *preSignedURL = [awsS3Utils getS3PreSignedURL:[Config config][@"AWSBucketName"] key:key configuration:configuration];
        [preSignedURLs addObject:preSignedURL];
    }
    int i = 0;
    for (NSString *url in preSignedURLs) {
        // ダウンロード後にどのファイルか判別できるように情報を入れておく
        // childObjectId, date, imageObjectId, section, row
        // id系はいろんな文字が入るので、スペースで区切る
        NSString *identifier = [NSString stringWithFormat:@"%@ %@ %@ %@ %@", transitionInfo[@"childObjectId"], transitionInfo[@"date"], transitionInfo[@"imageIds"][i], transitionInfo[@"section"], transitionInfo[@"row"]];
        NSURLSessionConfiguration *configuration;
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >=8.0f) {
            configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
        } else {
            configuration = [NSURLSessionConfiguration backgroundSessionConfiguration:identifier];
        }
        configuration.allowsCellularAccess = YES;
        NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
        NSString *forceStringURL = [NSString stringWithFormat:@"%@", url];
        NSURL *assetURL = [NSURL URLWithString:forceStringURL];
        NSURLSessionDownloadTask *task = [session downloadTaskWithURL:assetURL];
        [task resume];
        i++;
    }
    taskQueueCount = preSignedURLs.count;
}

- (void) URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    NSData *downloadedData = [NSData dataWithContentsOfURL:location];
    if ([downloadedData length] == 0) {
        return;
    }
    
    UIImage *downloadedThumbImage = [ImageCache makeThumbNail:[UIImage imageWithData:downloadedData]];
    NSData *thumbData = [[NSData alloc] initWithData:UIImageJPEGRepresentation(downloadedThumbImage, 0.7f)];
    
    NSString *identifier = session.configuration.identifier;
    NSArray *params = [identifier componentsSeparatedByString:@" "];
    // 0:childObjectId 1:date 2:imageId 3:section 4:row
    if ([params[3] isEqualToString:@"0"] && ([params[4] isEqualToString:@"0"] || [params[4] isEqualToString:@"1"])) {
        // candidateに追加
        [ImageCache setCache:params[2] image:thumbData dir:[NSString stringWithFormat:@"%@/candidate/%@/thumbnail", params[0], params[1]]];
    } else {
        // bestshotに追加
        [ImageCache setCache:params[1] image:thumbData dir:[NSString stringWithFormat:@"%@/bestShot/thumbnail", params[0]]];
    }
    
    taskQueueCount--;
    if (taskQueueCount == 0) {
        CompletionHandlerType handler = _completionHandlerArray[0];
        handler(UIBackgroundFetchResultNewData);
        [_completionHandlerArray removeAllObjects];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error) {
        taskQueueCount--;
        if (taskQueueCount == 0) {
            CompletionHandlerType handler = _completionHandlerArray[0];
            handler(UIBackgroundFetchResultNewData);
            [_completionHandlerArray removeAllObjects];
        }
    }
}

- (void) URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
{
}

- (void) URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
}

@end
