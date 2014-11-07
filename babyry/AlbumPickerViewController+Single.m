//
//  AlbumPickerViewController+Single.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/11/06.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "AlbumPickerViewController+Single.h"
#import "AlbumPickerViewController.h"
#import "ImageTrimming.h"
#import "Config.h"
#import "Logger.h"
#import "ImageCache.h"
#import "PushNotification.h"
#import "Partner.h"
#import "NotificationHistory.h"
#import "AWSCommon.h"

@implementation AlbumPickerViewController_Single

- (void) logicViewDidLoad
{
    // singleのアップロードの場合には、選択した画像を表示させておかないで一発でアップロードする
    _albumPickerViewController.selectedImageCollectionView.hidden = YES;
    _albumPickerViewController.sendImageLabel.hidden = YES;
    _albumPickerViewController.picNumLabel.hidden = YES;
    
    CGRect albumFrame = _albumPickerViewController.albumImageCollectionView.frame;
    float windowHeight = _albumPickerViewController.view.frame.size.height;
    CGRect albumFrameForSingle = CGRectMake(albumFrame.origin.x, albumFrame.origin.y, albumFrame.size.width, windowHeight - albumFrame.origin.y);
    _albumPickerViewController.albumImageCollectionView.frame = albumFrameForSingle;
}

- (void) logicSendImageButton:(NSIndexPath *)indexPath
{
    // 引数で受け取るindexPathはalbumに表示されている画像の位置
    NSLog(@"logicSendImageButton %@", indexPath);
    AWSServiceConfiguration *configuration = [AWSCommon getAWSServiceConfiguration:@"S3"];
    ALAsset *asset = _albumPickerViewController.sectionImageDic[_albumPickerViewController.sectionDateByIndex[indexPath.section]][indexPath.row];
    ALAssetRepresentation *representation = [asset defaultRepresentation];
    NSURL *assetURL = [[asset valueForProperty:ALAssetPropertyURLs] objectForKey:[[asset defaultRepresentation] UTI]];
    NSString *fileExtension = [[assetURL path] pathExtension];
    
    UIImage *originalImage = [UIImage imageWithCGImage:[representation fullResolutionImage] scale:[representation scale] orientation:(UIImageOrientation)[representation orientation]];
    UIImage *resizedImage = [ImageTrimming resizeImageForUpload:originalImage];
    
    NSData *imageData = [[NSData alloc] init];
    NSString *imageType = [[NSString alloc] init];
    if ([fileExtension isEqualToString:@"PNG"]) {
        imageData = UIImagePNGRepresentation(resizedImage);
        imageType = @"image/png";
    } else {
        imageData = UIImageJPEGRepresentation(resizedImage, 0.7f);
        imageType = @"image/jpeg";
    }
    
    // ImageViewにセット
    if (_albumPickerViewController.uploadViewController) {
        _albumPickerViewController.uploadViewController.scrollView.frame = [self getUploadedImageFrame:resizedImage];
        _albumPickerViewController.uploadViewController.uploadedImageView.frame = CGRectMake(0, 0, _albumPickerViewController.uploadViewController.scrollView.frame.size.width, _albumPickerViewController.uploadViewController.scrollView.frame.size.height);
        [_albumPickerViewController.uploadViewController.uploadedImageView setImage:resizedImage];
    }
    
    PFQuery *imageQuery = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%ld", (long)[_albumPickerViewController.childProperty[@"childImageShardIndex"] integerValue]]];
    [imageQuery whereKey:@"imageOf" equalTo:_albumPickerViewController.childObjectId];
    [imageQuery whereKey:@"date" equalTo:[NSNumber numberWithInteger:[_albumPickerViewController.date integerValue]]];
    [imageQuery whereKey:@"bestFlag" equalTo:@"choosed"];
    
    NSArray *imageArray = [imageQuery findObjects];
    NSLog(@"imageArrayが一つ以上あったら(objectId指定だから一つしか無いはずだけど)上書き");
    if ([imageArray count] > 1) {
    } else if ([imageArray count] == 1) {
        NSLog(@"found one object");
        PFObject *tmpImageObject = imageArray[0];
        //imageArray[0][@"imageFile"] = imageFile;
        imageArray[0][@"bestFlag"] = @"choosed";
        [imageArray[0] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
            if (succeeded) {
                AWSS3PutObjectRequest *putRequest = [AWSS3PutObjectRequest new];
                putRequest.bucket = [Config config][@"AWSBucketName"];
                putRequest.key = [NSString stringWithFormat:@"%@/%@", [NSString stringWithFormat:@"ChildImage%ld", (long)[_albumPickerViewController.childProperty[@"childImageShardIndex"] integerValue]], tmpImageObject.objectId];
                putRequest.body = imageData;
                putRequest.contentLength = [NSNumber numberWithLong:[imageData length]];
                putRequest.contentType = imageType;
                putRequest.cacheControl = @"no-cache";
                
                AWSS3 *awsS3 = [[AWSS3 new] initWithConfiguration:configuration];
                [[awsS3 putObject:putRequest] continueWithBlock:^id(BFTask *task) {
                    if (task.error) {
                        [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in Save to S3 : %@", task.error]];
                    }
                    return nil;
                }];
            }
            if (error) {
                [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in save best flag : %@", error]];
            }
        }];
    } else {
        NSLog(@"not found object");
        PFObject *childImage = [PFObject objectWithClassName:[NSString stringWithFormat:@"ChildImage%ld", (long)[_albumPickerViewController.childProperty[@"childImageShardIndex"] integerValue]]];
        childImage[@"date"] = [NSNumber numberWithInteger:[_albumPickerViewController.date integerValue]];
        childImage[@"imageOf"] = _albumPickerViewController.childObjectId;
        childImage[@"bestFlag"] = @"choosed";
        [childImage saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
            if (succeeded) {
                AWSS3PutObjectRequest *putRequest = [AWSS3PutObjectRequest new];
                putRequest.bucket = [Config config][@"AWSBucketName"];
                putRequest.key = [NSString stringWithFormat:@"%@/%@", [NSString stringWithFormat:@"ChildImage%ld", (long)[_albumPickerViewController.childProperty[@"childImageShardIndex"] integerValue]], childImage.objectId];
                putRequest.body = imageData;
                putRequest.contentLength = [NSNumber numberWithLong:[imageData length]];
                putRequest.contentType = imageType;
                putRequest.cacheControl = @"no-cache";
                
                AWSS3 *awsS3 = [[AWSS3 new] initWithConfiguration:configuration];
                [[awsS3 putObject:putRequest] continueWithBlock:^id(BFTask *task) {
                    if (task.error) {
                        [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in get image from s3 : %@", task.error]];
                    }
                    return nil;
                }];
            }
            if (error) {
                [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in get bestShot : %@", error]];
            }
        }];
    }
    
    // Cache set use thumbnail (フォトライブラリにあるやつは正方形になってるし使わない)
    UIImage *thumbImage = [ImageCache makeThumbNail:resizedImage];
    [ImageCache
     setCache:_albumPickerViewController.date
     image:UIImageJPEGRepresentation(thumbImage, 0.7f)
     dir:[NSString stringWithFormat:@"%@/bestShot/thumbnail", _albumPickerViewController.childObjectId]
     ];
    
    NSMutableDictionary *transitionInfoDic = [[NSMutableDictionary alloc] init];
    transitionInfoDic[@"event"] = @"imageUpload";
    transitionInfoDic[@"date"] = _albumPickerViewController.date;
    transitionInfoDic[@"section"] = [NSString stringWithFormat:@"%d", indexPath.section];
    transitionInfoDic[@"row"] = [NSString stringWithFormat:@"%d", indexPath.row];
    transitionInfoDic[@"childObjectId"] = _albumPickerViewController.childObjectId;
    NSMutableDictionary *options = [[NSMutableDictionary alloc]init];
    options[@"data"] = [[NSMutableDictionary alloc]
                        initWithObjects:@[@"Increment", transitionInfoDic]
                        forKeys:@[@"badge", @"transitionInfo"]];
    [PushNotification sendInBackground:@"imageUpload" withOptions:options];
    PFObject *partner = (PFUser *)[Partner partnerUser];
    [NotificationHistory createNotificationHistoryWithType:@"imageUploaded" withTo:partner[@"userId"] withChild:_albumPickerViewController.childObjectId withDate:[_albumPickerViewController.date integerValue]];
    
    NSLog(@"popViewController");
    [_albumPickerViewController dismissViewControllerAnimated:YES completion:nil];
    //アルバム表示のViewも消す
    UINavigationController *naviController = (UINavigationController *)_albumPickerViewController.presentingViewController;
    [naviController popViewControllerAnimated:YES];
}

-(CGRect) getUploadedImageFrame:(UIImage *) image
{
    float imageViewAspect = _albumPickerViewController.uploadViewController.defaultImageViewFrame.size.width/_albumPickerViewController.uploadViewController.defaultImageViewFrame.size.height;
    float imageAspect = image.size.width/image.size.height;
    
    // 横長バージョン
    // 枠より、画像の方が横長、枠の縦を縮める
    CGRect frame = _albumPickerViewController.uploadViewController.defaultImageViewFrame;
    if (imageAspect >= imageViewAspect){
        frame.size.height = frame.size.width/imageAspect;
        // 縦長バージョン
        // 枠より、画像の方が縦長、枠の横を縮める
    } else {
        frame.size.width = frame.size.height*imageAspect;
    }
    
    frame.origin.x = (_albumPickerViewController.view.frame.size.width - frame.size.width)/2;
    frame.origin.y = (_albumPickerViewController.view.frame.size.height - frame.size.height)/2;
    
    return frame;
}

@end
