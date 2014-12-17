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
BOOL isUploading = false;

@implementation ImageUploadInBackground

+ (void)setMultiUploadImageDataSet:(NSMutableDictionary *)property multiUploadImageDataArray:(NSMutableArray *)imageDataArray multiUploadImageDataTypeArray:(NSMutableArray *)imageDataTypeArray date:(NSString *)date indexPath:(NSIndexPath *)indexPath
{
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
}

+ (int)getUploadingQueueCount
{
    return uploadingQueueCount;
}

+ (int)getIsUploading
{
    return isUploading;
}

+ (void)multiUploadImagesInBackground
{
    // tmpDataの運用を厳密にする (クルクルが消えないとかそうゆうのを無くす)
    // 一つの画像をアップするのに時間がかかるけど、安全な方を選ぶ。時間がかかると言っても電波状況が通常であれば数秒
    // 1. ParseにtmpDataを作成する
    // 2. S3に画像を上げる
    // 3. ParseのtmpDataをFalseにセットする
    // 1~3が全て完了した画像のみ表示させる
    
    isUploading = YES;
    
    // multiUploadImageDataArrayをひとつづつ再帰的に処理していく
    if ([multiUploadImageDataArray count] > 0) {
        
        // 1. ParseにtmpDataを作成する(tmpData = TRUE)
        PFObject *childImage = [PFObject objectWithClassName:[NSString stringWithFormat:@"ChildImage%ld", (long)[childProperty[@"childImageShardIndex"] integerValue]]];
        childImage[@"date"] = [NSNumber numberWithInteger:[targetDate integerValue]];
        childImage[@"imageOf"] = childProperty[@"objectId"];
        childImage[@"bestFlag"] = @"unchoosed";
        childImage[@"isTmpData"] = @"TRUE";
        [childImage saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
            if(succeeded) {
                // 2. S3に画像を上げる
                AWSS3PutObjectRequest *putRequest = [AWSS3PutObjectRequest new];
                putRequest.bucket = [Config config][@"AWSBucketName"];
                putRequest.key = [NSString stringWithFormat:@"%@/%@", [NSString stringWithFormat:@"ChildImage%ld", (long)[childProperty[@"childImageShardIndex"] integerValue]], childImage.objectId];
                putRequest.body = [multiUploadImageDataArray objectAtIndex:0];
                putRequest.contentLength = [NSNumber numberWithLong:[[multiUploadImageDataArray objectAtIndex:0] length]];
                putRequest.contentType = [multiUploadImageDataTypeArray objectAtIndex:0];
                putRequest.cacheControl = @"no-cache";
                AWSS3 *awsS3 = [[AWSS3 new] initWithConfiguration:configuration];
                [[awsS3 putObject:putRequest] continueWithBlock:^id(BFTask *task) {
                    if (task.error) {
                        // S3にアップが失敗したらEventuallyでchildImageを削除する
                        [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in uploading new image to S3 : %@", task.error]];
                        [childImage deleteEventually];
                        // リトライした方が良いと思うけど、ひとまずキューを削除して次のキューにいく
                        uploadingQueueCount--;
                        [multiUploadImageDataArray removeObjectAtIndex:0];
                        [multiUploadImageDataTypeArray removeObjectAtIndex:0];
                        [self multiUploadImagesInBackground];
                    } else {
                        // 3. ParseのtmpDataをFalseにセットする
                        childImage[@"isTmpData"] = @"FALSE";
                        [childImage saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
                            if (succeeded) {
                                completeUploadCount++;
                            }
                            if (error) {

                            }
                            // エラーでもエラーじゃなくても今のキューを削除して次のキューに
                            uploadingQueueCount--;
                            [multiUploadImageDataArray removeObjectAtIndex:0];
                            [multiUploadImageDataTypeArray removeObjectAtIndex:0];
                            [self multiUploadImagesInBackground];
                        }];
                    }
                    return nil;
                }];
            }
            if (error) {
                [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in making new object for new image : %@", error]];
                // PFObjectも出来ていないのでもう一回リトライ
                [self multiUploadImagesInBackground];
            }
        }];
    } else {
        [self afterUpload];
    }
}

+ (void)afterUpload
{
    isUploading = false;

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
