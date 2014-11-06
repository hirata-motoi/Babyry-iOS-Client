//
//  ImageUploadInBackground.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/11/05.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ImageUploadInBackground.h"
#import "AWSS3Utils.h"
#import <Parse/Parse.h>
#import "Logger.h"
#import "Config.h"
#import "Partner.h"
#import "NotificationHistory.h"
#import "PushNotification.h"
#import "Tutorial.h"
#import "MultiUploadViewController+Logic.h"

NSMutableArray *multiUploadImageDataArray;
NSMutableArray *multiUploadImageDataTypeArray;
NSMutableDictionary *childProperty;
NSMutableArray *tmpImageArray;
NSString *targetDate;
NSIndexPath *targetIndexPath;
AWSServiceConfiguration *configuration;
BOOL uploadSucceeded;

@implementation ImageUploadInBackground

+ (void)setMultiUploadImageDataSet:(NSMutableDictionary *)property multiUploadImageDataArray:(NSMutableArray *)imageDataArray multiUploadImageDataTypeArray:(NSMutableArray *)imageDataTypeArray date:(NSString *)date indexPath:(NSIndexPath *)indexPath
{
    childProperty = [[NSMutableDictionary alloc] initWithDictionary:property];
    multiUploadImageDataArray = [[NSMutableArray alloc] initWithArray:imageDataArray];
    multiUploadImageDataTypeArray = [[NSMutableArray alloc] initWithArray:imageDataTypeArray];
    targetDate = date;
    targetIndexPath = indexPath;
}

+ (int)numOfWillUploadImages
{
    return [multiUploadImageDataArray count];
}

+ (void)multiUploadToParseInBackground
{
    configuration = [AWSS3Utils getAWSServiceConfiguration];
    PFQuery *tmpImageQuery = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%ld", (long)[childProperty[@"childImageShardIndex"] integerValue]]];
    [tmpImageQuery whereKey:@"imageOf" equalTo:childProperty[@"objectId"]];
    [tmpImageQuery whereKey:@"isTmpData" equalTo:@"TRUE"];
    [tmpImageQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if (objects) {
            tmpImageArray = [[NSMutableArray alloc] initWithArray:objects];
            uploadSucceeded = NO;
            [self recursiveUploadImageToS3];
            if (uploadSucceeded) {
                [self afterUpload];
            }
        }
        if (error) {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in get TmpImage : %@", error]];
        }
    }];
}

+ (void)recursiveUploadImageToS3
{
    if ([tmpImageArray count] > 0) {
        //NSLog(@"S3に上げる");
        PFObject *object = tmpImageArray[0];
        AWSS3PutObjectRequest *putRequest = [AWSS3PutObjectRequest new];
        putRequest.bucket = [Config config][@"AWSBucketName"];
        putRequest.key = [NSString stringWithFormat:@"%@/%@", [NSString stringWithFormat:@"ChildImage%ld", (long)[childProperty[@"childImageShardIndex"] integerValue]], object.objectId];
        putRequest.body = [multiUploadImageDataArray objectAtIndex:0];
        putRequest.contentLength = [NSNumber numberWithLong:[[multiUploadImageDataArray objectAtIndex:0] length]];
        putRequest.contentType = [multiUploadImageDataTypeArray objectAtIndex:0];
        putRequest.cacheControl = @"no-cache";
        AWSS3 *awsS3 = [[AWSS3 new] initWithConfiguration:configuration];
        //NSLog(@"start put to S3");
        [[awsS3 putObject:putRequest] continueWithBlock:^id(BFTask *task) {
            if (!task.error) {
                //NSLog(@"エラーがなければisTmpDataを更新");
                object[@"isTmpData"] = @"FALSE";
                [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
                    if (error) {
                        [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in update isTmpData record : %@", error]];
                    }
                    //NSLog(@"tmpImageArrayは0以上だけどmultiUploadImageDataArrayが0の可能性あり (前回にゴミが残っているパターン)");
                    if ([multiUploadImageDataArray count] == 0) {
                        [self removeTmpImages:tmpImageArray];
                        return;
                    }
                    [multiUploadImageDataArray removeObjectAtIndex:0];
                    [multiUploadImageDataTypeArray removeObjectAtIndex:0];
                    [tmpImageArray removeObjectAtIndex:0];
                    uploadSucceeded = YES;
                    [self recursiveUploadImageToS3];
                }];
            } else {
                [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in putRequest to S3 : %@", task.error]];
                // 失敗したらレコードごと消す(でいいのかな？リトライ？)
                [object deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
                    if (error) {
                        [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in delete record for failed data : %@", error]];
                    }
                    if ([multiUploadImageDataArray count] == 0) {
                        [self removeTmpImages:tmpImageArray];
                        return;
                    }
                    [multiUploadImageDataArray removeObjectAtIndex:0];
                    [multiUploadImageDataTypeArray removeObjectAtIndex:0];
                    [tmpImageArray removeObjectAtIndex:0];
                    [self recursiveUploadImageToS3];
                }];
            }
            return nil;
        }];
    } else {
        //NSLog(@"tmpDataは終わり");
        if ([multiUploadImageDataArray count] > 0) {
            //NSLog(@"TmpDataで取得した数よりもmultiUploadImageDataArrayの数の方が多い");
            // => ParseにTmpDataの保存を失敗しているので最初から作る
            PFObject *childImage = [PFObject objectWithClassName:[NSString stringWithFormat:@"ChildImage%ld", (long)[childProperty[@"childImageShardIndex"] integerValue]]];
            childImage[@"date"] = [NSNumber numberWithInteger:[targetDate integerValue]];
            childImage[@"imageOf"] = childProperty[@"objectId"];
            childImage[@"bestFlag"] = @"unchoosed";
            [childImage saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
                if(succeeded) {
                    // S3に上げる
                    AWSS3PutObjectRequest *putRequest = [AWSS3PutObjectRequest new];
                    putRequest.bucket = [Config config][@"AWSBucketName"];
                    putRequest.key = [NSString stringWithFormat:@"%@/%@", [NSString stringWithFormat:@"ChildImage%ld", (long)[childProperty[@"childImageShardIndex"] integerValue]], childImage.objectId];
                    putRequest.body = [multiUploadImageDataArray objectAtIndex:0];
                    putRequest.contentLength = [NSNumber numberWithLong:[[multiUploadImageDataArray objectAtIndex:0] length]];
                    putRequest.contentType = [multiUploadImageDataTypeArray objectAtIndex:0];
                    putRequest.cacheControl = @"no-cache";
                    AWSS3 *awsS3 = [[AWSS3 new] initWithConfiguration:configuration];
                    [[awsS3 putObject:putRequest] continueWithBlock:^id(BFTask *task) {
                        if (!task.error) {
                            // エラーがなければisTmpDataを更新
                            [multiUploadImageDataArray removeObjectAtIndex:0];
                            [multiUploadImageDataTypeArray removeObjectAtIndex:0];
                            uploadSucceeded = YES;
                            [self recursiveUploadImageToS3];
                        } else {
                            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in uploading new image to S3 : %@", task.error]];
                            // PFObjectを消した上でリトライ(multiUploadImageDataArrayの対象行を消さなければもう一回同じ事してくれる)
                            // TODO : 本当にNWの調子が悪いとき用に失敗したらゴミを消して終了の方が良いかも
                            [childImage deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
                                if (error) {
                                    [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in delete record for failed data of new childimage : %@", error]];
                                }
                                [self recursiveUploadImageToS3];
                            }];
                        }
                        return nil;
                    }];
                }
                if (error) {
                    [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in making new object for new image : %@", error]];
                    // PFObjectも出来ていないのでもう一回リトライ
                    [self recursiveUploadImageToS3];
                }
            }];
        }
    }
}

+ (void)removeTmpImages:(NSArray *)objects
{
    for (PFObject *object in objects) {
        [object deleteInBackground];
    }
}

+ (void)afterUpload
{
    // NotificationHistoryに登録
    PFObject *partner = (PFObject *)[Partner partnerUser];
    [NotificationHistory createNotificationHistoryWithType:@"imageUploaded" withTo:partner[@"userId"] withChild:childProperty[@"objectId"] withDate:[targetDate integerValue]];
    
    // push通知
    // message以外にも、タップしたところが分かる情報を飛ばす
    NSMutableDictionary *transitionInfoDic = [[NSMutableDictionary alloc] init];
    transitionInfoDic[@"event"] = @"imageUpload";
    transitionInfoDic[@"date"] = targetDate;
    transitionInfoDic[@"section"] = [NSString stringWithFormat:@"%d", targetIndexPath.section];
    transitionInfoDic[@"row"] = [NSString stringWithFormat:@"%d", targetIndexPath.row];
    transitionInfoDic[@"childObjectId"] = childProperty[@"objectId"];
    NSMutableDictionary *options = [[NSMutableDictionary alloc]init];
    options[@"data"] = [[NSMutableDictionary alloc]
                        initWithObjects:@[@"Increment", transitionInfoDic]
                        forKeys:@[@"badge", @"transitionInfo"]];
    [PushNotification sendInBackground:@"imageUpload" withOptions:options];
    
    if ([Tutorial underTutorial]) {
        // best shotを選んであげる
        MultiUploadViewController_Logic *logic = [[MultiUploadViewController_Logic alloc]init];
        [logic updateBestShotWithChild:childProperty[@"objectId"] withDate:targetDate];
    }
}
 
@end
