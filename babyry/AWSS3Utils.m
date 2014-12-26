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

@implementation AWSS3Utils

- (void)makeCacheFromS3:(NSMutableArray *)downloadQueue configuration:(AWSServiceConfiguration *)configuration withBlock:(makeCacheFromS3Block)block
{
	if ([downloadQueue count] == 0) {
		block();
	}

	AWSS3TransferManager *transferManager = [[AWSS3TransferManager alloc] initWithConfiguration:configuration identifier:@"S3"];
	
	int __block executedCount = 0;
	for (NSMutableDictionary *queue in downloadQueue) {
		
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
					[Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in makeCacheFromS3 (objectId:%@, childObjectId:%@) : %@", queue[@"objectId"], queue[@"childObjectId"], task.error]];
				}
			}
			if (task.result) {
				AWSS3TransferManagerDownloadOutput *downloadOutput = task.result;
				//File downloaded successfully.
				
				NSData *downloadData = [NSData dataWithContentsOfURL:downloadOutput.body];
				UIImage *downloadImage = [ImageCache makeThumbNail:[UIImage imageWithData:downloadData]];
				if (!queue[@"imageType"] || [queue[@"imageType"] isEqualToString:@"fullsize"]) {
					if ([queue[@"imageType"] isEqualToString:@"fullsize"]) {
						// fullsizeのimageをcache
						[ImageCache
						 setCache:[queue[@"date"] stringValue]
						 image:downloadData
						 dir:[NSString stringWithFormat:@"%@/bestShot/fullsize", queue[@"childObjectId"]]
						 ];
					}
					// ChileImageオブジェクトのupdatedAtとtimestampを比較するためthumbnailは常に作る
					[ImageCache
					 setCache:[queue[@"date"] stringValue]
					 image:UIImageJPEGRepresentation(downloadImage, 0.7f)
					 dir:[NSString stringWithFormat:@"%@/bestShot/thumbnail", queue[@"childObjectId"]]
					 ];
				} else if ([queue[@"imageType"] isEqualToString:@"candidate"]) {
					[ImageCache
					 setCache:queue[@"objectId"]
					 image:UIImageJPEGRepresentation(downloadImage, 0.7f)
					 dir:[NSString stringWithFormat:@"%@/candidate/%@/thumbnail", queue[@"childObjectId"], queue[@"date"]]
					 ];
					[ImageCache
					 setCache:queue[@"objectId"]
					 image:downloadData
					 dir:[NSString stringWithFormat:@"%@/candidate/%@/fullsize", queue[@"childObjectId"], queue[@"date"]]
					 ];
				}
				[ImageCache removeCache:[NSString stringWithFormat:@"%@/candidate/%@/thumbnail/%@-tmp", queue[@"childObjectId"], queue[@"date"], queue[@"objectId"]]];
			}
			
			// エラーも含め全てのキューが終わったらblockを返す
			// エラーになった物はキャッシュがセットされていないので画像が表示されないだけ(もう一度やって成功すれば表示される)
			executedCount++;
			if (executedCount == [downloadQueue count]) {
				block();
			}
			return nil;
		}];
	}
}

@end
