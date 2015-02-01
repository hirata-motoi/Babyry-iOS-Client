//
//  ImageUploadInBackground.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/11/05.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ImageUploadInBackground.h"
#import <Parse/Parse.h>
#import "Logger.h"
#import "Config.h"
#import "Partner.h"
#import "NotificationHistory.h"
#import "PushNotification.h"
#import "Tutorial.h"
#import "MultiUploadViewController+Logic.h"
#import "AWSCommon.h"

NSMutableArray *multiUploadImageDataArray;
NSMutableArray *multiUploadImageDataTypeArray;
NSMutableDictionary *childProperty;
NSMutableArray *tmpImageArray;
NSString *targetDate;
NSIndexPath *targetIndexPath;
AWSServiceConfiguration *configuration;
int completeUploadCount;
int uploadingQueueCount = 0;
BOOL isUploading = NO;
int uploadErrorCount;

@implementation ImageUploadInBackground

+ (void)setMultiUploadImageDataSet:(NSMutableDictionary *)property multiUploadImageDataArray:(NSMutableArray *)imageDataArray multiUploadImageDataTypeArray:(NSMutableArray *)imageDataTypeArray date:(NSString *)date indexPath:(NSIndexPath *)indexPath
{
    NSLog(@"setMultiUploadImageDataSet check mem %@", self);
    childProperty = [[NSMutableDictionary alloc] initWithDictionary:property];
    multiUploadImageDataArray = [[NSMutableArray alloc] initWithArray:imageDataArray];
    multiUploadImageDataTypeArray = [[NSMutableArray alloc] initWithArray:imageDataTypeArray];
    targetDate = date;
    targetIndexPath = indexPath;
    completeUploadCount = 0;
    configuration = [AWSCommon getAWSServiceConfiguration:@"S3"];
    
    // アップロード中のキュー数を保持
    // MultiUpload画面のクルクル表示に使う
    uploadingQueueCount = [multiUploadImageDataArray count];
    uploadErrorCount = 0;
}

+ (int)getUploadingQueueCount
{
    NSLog(@"getUploadingQueueCount check mem %@", self);
    return uploadingQueueCount;
}

+ (int)getIsUploading
{
    NSLog(@"getIsUploading check mem %@", self);
    return isUploading;
}

+ (void)multiUploadImagesInBackground
{
    NSLog(@"multiUploadImagesInBackground check mem %@", self);
    NSLog(@"multiUploadImagesInBackground たまにクルクルが消えないのでログし込む by kenjiszk");
    // tmpDataの運用を厳密にする (クルクルが消えないとかそうゆうのを無くす)
    // 一つの画像をアップするのに時間がかかるけど、安全な方を選ぶ。時間がかかると言っても電波状況が通常であれば数秒
    // 1. ParseにtmpDataを作成する
    // 2. S3に画像を上げる
    // 3. ParseのtmpDataをFalseにセットする
    // 1~3が全て完了した画像のみ表示させる
    
    isUploading = YES;
    
    NSMutableArray *imageIds = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < [multiUploadImageDataArray count]; i++) {
        NSData *imageData = [multiUploadImageDataArray objectAtIndex:i];
        NSString *imageType = [multiUploadImageDataTypeArray objectAtIndex:i];
        
        // 1. ParseにtmpDataを作成する(tmpData = TRUE)
        NSLog(@"ParseにtmpDataを作成する(tmpData = TRUE) %d", i);
        PFObject *childImage = [PFObject objectWithClassName:[NSString stringWithFormat:@"ChildImage%ld", (long)[childProperty[@"childImageShardIndex"] integerValue]]];
        childImage[@"date"] = [NSNumber numberWithInteger:[targetDate integerValue]];
        childImage[@"imageOf"] = childProperty[@"objectId"];
        childImage[@"bestFlag"] = @"unchoosed";
        childImage[@"isTmpData"] = @"TRUE";
        [childImage saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
            if (succeeded) {
                NSLog(@"success to save in Parse");
                AWSS3PutObjectRequest *putRequest = [AWSS3PutObjectRequest new];
                putRequest.bucket = [Config config][@"AWSBucketName"];
                putRequest.key = [NSString stringWithFormat:@"%@/%@", [NSString stringWithFormat:@"ChildImage%ld", (long)[childProperty[@"childImageShardIndex"] integerValue]], childImage.objectId];
                putRequest.body = imageData;
                putRequest.contentLength = [NSNumber numberWithLong:[imageData length]];
                putRequest.contentType = imageType;
                putRequest.cacheControl = @"no-cache";
                AWSS3 *awsS3 = [[AWSS3 new] initWithConfiguration:configuration];
                [[awsS3 putObject:putRequest] continueWithBlock:^id(BFTask *task) {
                    
                    if (task.error) {
                        NSLog(@"error");
                        // S3にアップが失敗したらEventuallyでchildImageを削除する
                        [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in uploading new image(%@) to S3 : %@", childImage.objectId, task.error]];
                        [childImage deleteEventually];
                        uploadErrorCount++;
                    }
                    if (task.result) {
                        NSLog(@"success");
                        NSLog(@"success to save in S3 %@ %@ %@", task, putRequest.contentLength, putRequest.key);
                        // 3. ParseのtmpDataをFalseにセットする
                        childImage[@"isTmpData"] = @"FALSE";
                        NSError *error = nil;
                        [childImage save:&error];
                        if (!error) {
                            completeUploadCount++;
                            [imageIds addObject:childImage.objectId];
                        } else {
                            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in changing tmpData true to false : %@", error]];
                            uploadErrorCount++;
                        }
                    }
                    uploadingQueueCount--;
                    if (uploadingQueueCount < 1) {
                        [self afterUpload:[NSString stringWithFormat:@"ChildImage%ld", (long)[childProperty[@"childImageShardIndex"] integerValue]] imageIds:imageIds];
                    }
                    return nil;
                }];
            } else {
                [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in making new object for new image : %@", error]];
                uploadErrorCount++;
                uploadingQueueCount--;
                if (uploadingQueueCount < 1) {
                    [self afterUpload:[NSString stringWithFormat:@"ChildImage%ld", (long)[childProperty[@"childImageShardIndex"] integerValue]] imageIds:imageIds];
                }
            }
        }];
    }
}

+ (void)afterUpload:(NSString *)dirName imageIds:(NSArray *)imageIds
{
    NSLog(@"afterUpload check mem %@", self);
    isUploading = NO;
    
    if (uploadErrorCount > 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%d枚の画像アップロードに失敗しました", uploadErrorCount]
                                                        message:@"もう一度アップロードを行ってください。"
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"OK", nil
                              ];
        [alert show];
    }

    // NotificationHistoryに登録
    PFObject *partner = (PFObject *)[Partner partnerUser];
    [NotificationHistory createNotificationHistoryWithType:@"imageUploaded" withTo:partner[@"userId"] withChild:childProperty[@"objectId"] withDate:[targetDate integerValue]];
    
    uploadingQueueCount = 0;
    
    if (completeUploadCount > 0) {
        // push通知
        // message以外にも、タップしたところが分かる情報を飛ばす
        NSMutableDictionary *transitionInfoDic = [[NSMutableDictionary alloc] init];
        transitionInfoDic[@"event"] = @"imageUpload";
        transitionInfoDic[@"date"] = targetDate;
        transitionInfoDic[@"section"] = [NSString stringWithFormat:@"%ld", (long)targetIndexPath.section];
        transitionInfoDic[@"row"] = [NSString stringWithFormat:@"%ld", (long)targetIndexPath.row];
        transitionInfoDic[@"childObjectId"] = childProperty[@"objectId"];
        transitionInfoDic[@"dirName"] = dirName;
        transitionInfoDic[@"imageIds"] = imageIds;
        NSMutableDictionary *options = [[NSMutableDictionary alloc]init];
        options[@"data"] = [[NSMutableDictionary alloc]
                            initWithObjects:@[@"Increment", transitionInfoDic]
                            forKeys:@[@"badge", @"transitionInfo"]];
        [PushNotification sendInBackground:@"imageUpload" withOptions:options];
        completeUploadCount = 0;
    }
    
    if ([Tutorial underTutorial]) {
        // best shotを選んであげる
        MultiUploadViewController_Logic *logic = [[MultiUploadViewController_Logic alloc]init];
        [logic updateBestShotWithChild:childProperty[@"objectId"] withDate:targetDate];
    }
}

@end
