//
//  UploadPickerViewController.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/08/11.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "UploadPickerViewController.h"
#import "ImageTrimming.h"
#import "ImageCache.h"
#import "PushNotification.h"
#import "Partner.h"
#import "NotificationHistory.h"
#import "Config.h"
#import "Logger.h"

@interface UploadPickerViewController ()

@end

@implementation UploadPickerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _configuration = [AWSS3Utils getAWSServiceConfiguration];
    
    [self openPhotoLibrary];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)openPhotoLibrary
{
    // インタフェース使用可能なら
	if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
	{
        // UIImageControllerの初期化
		UIImagePickerController *imagePickerController = [[UIImagePickerController alloc]init];
		[imagePickerController setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
		[imagePickerController setAllowsEditing:NO];
		[imagePickerController setDelegate:self];
		
        [self presentViewController:imagePickerController animated:YES completion: nil];
	}
	else
	{
		NSLog(@"photo library invalid.");
	}
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // 拡張子取得
    NSURL *assetURL = [info objectForKey:UIImagePickerControllerReferenceURL];
    NSString *fileExtension = [[assetURL path] pathExtension];
    
    // オリジナルイメージ取得
	UIImage *originalImage = (UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage];
    
    // リサイズ
    UIImage *resizedImage = [ImageTrimming resizeImageForUpload:originalImage];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popViewControllerAnimated:YES];
    
    // ImageViewにセット
    if (_uploadViewController) {
        _uploadViewController.scrollView.frame = [self getUploadedImageFrame:resizedImage];
        _uploadViewController.uploadedImageView.frame = CGRectMake(0, 0, _uploadViewController.scrollView.frame.size.width, _uploadViewController.scrollView.frame.size.height);
        [_uploadViewController.uploadedImageView setImage:resizedImage];
    }
    
    // bestshot決定済みに変更
    if (_totalImageNum) {
        [_totalImageNum replaceObjectAtIndex:_indexPath.row withObject:[NSNumber numberWithInt:9999]];
    }
    
    NSData *imageData = [[NSData alloc] init];
    NSString *imageType = [[NSString alloc] init];
    // PNGは透過しないとだめなのでやる
    // その他はJPG
    // TODO 画像圧縮率
    if ([fileExtension isEqualToString:@"PNG"]) {
        imageData = UIImagePNGRepresentation(resizedImage);
        imageType = @"image/png";
    } else {
        imageData = UIImageJPEGRepresentation(resizedImage, 0.7f);
        imageType = @"image/jpeg";
    }
    
    PFQuery *imageQuery = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%ld", (long)[_child[@"childImageShardIndex"] integerValue]]];
    [imageQuery whereKey:@"imageOf" equalTo:_childObjectId];
    [imageQuery whereKey:@"date" equalTo:[NSNumber numberWithInteger:[_date integerValue]]];
    [imageQuery whereKey:@"bestFlag" equalTo:@"choosed"];
    
    NSArray *imageArray = [imageQuery findObjects];
    // imageArrayが一つ以上あったら(objectId指定だから一つしか無いはずだけど)上書き
    if ([imageArray count] > 1) {
    } else if ([imageArray count] == 1) {
        PFObject *tmpImageObject = imageArray[0];
        //imageArray[0][@"imageFile"] = imageFile;
        imageArray[0][@"bestFlag"] = @"choosed";
        [imageArray[0] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
            if (succeeded) {
                AWSS3PutObjectRequest *putRequest = [AWSS3PutObjectRequest new];
                putRequest.bucket = [Config getBucketName];
                putRequest.key = [NSString stringWithFormat:@"%@/%@", [NSString stringWithFormat:@"ChildImage%ld", (long)[_child[@"childImageShardIndex"] integerValue]], tmpImageObject.objectId];
                putRequest.body = imageData;
                putRequest.contentLength = [NSNumber numberWithLong:[imageData length]];
                putRequest.contentType = imageType;
                putRequest.cacheControl = @"no-cache";
                
                AWSS3 *awsS3 = [[AWSS3 new] initWithConfiguration:_configuration];
                [[awsS3 putObject:putRequest] continueWithBlock:^id(BFTask *task) {
                    if (task.error) {
                        [Logger writeParse:@"crit" message:[NSString stringWithFormat:@"Error in Save to S3 : %@", task.error]];
                    }
                    return nil;
                }];
            }
            if (error) {
                [Logger writeParse:@"crit" message:[NSString stringWithFormat:@"Error in save best flag : %@", error]];
            }
        }];
        // PageContentViewController.childImagesの中身に追加
        [_section[@"images"] replaceObjectAtIndex:_indexPath.row withObject:tmpImageObject];
    } else {
        PFObject *childImage = [PFObject objectWithClassName:[NSString stringWithFormat:@"ChildImage%ld", (long)[_child[@"childImageShardIndex"] integerValue]]];
        //childImage[@"imageFile"] = imageFile;
        // D(文字)つけないとwhere句のfieldに指定出来ないので付ける
        childImage[@"date"] = [NSNumber numberWithInteger:[_date integerValue]];
        childImage[@"imageOf"] = _childObjectId;
        childImage[@"bestFlag"] = @"choosed";
        [childImage saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
            if (succeeded) {
                AWSS3PutObjectRequest *putRequest = [AWSS3PutObjectRequest new];
                putRequest.bucket = [Config getBucketName];
                putRequest.key = [NSString stringWithFormat:@"%@/%@", [NSString stringWithFormat:@"ChildImage%ld", (long)[_child[@"childImageShardIndex"] integerValue]], childImage.objectId];
                putRequest.body = imageData;
                putRequest.contentLength = [NSNumber numberWithLong:[imageData length]];
                putRequest.contentType = imageType;
                putRequest.cacheControl = @"no-cache";
                
                AWSS3 *awsS3 = [[AWSS3 new] initWithConfiguration:_configuration];
                [[awsS3 putObject:putRequest] continueWithBlock:^id(BFTask *task) {
                    if (task.error) {
                        [Logger writeParse:@"crit" message:[NSString stringWithFormat:@"Error in get image from s3 : %@", task.error]];
                    }
                    return nil;
                }];
            }
            if (error) {
                [Logger writeParse:@"crit" message:[NSString stringWithFormat:@"Error in get bestShot : %@", error]];
            }
        }];
        
        // PageContentViewController.childImagesの中身に追加
        [_section[@"images"] replaceObjectAtIndex:_indexPath.row withObject:childImage];
    }
    
    // Cache set use thumbnail (フォトライブラリにあるやつは正方形になってるし使わない)
    UIImage *thumbImage = [ImageCache makeThumbNail:resizedImage];
    [ImageCache setCache:[NSString stringWithFormat:@"%@%@thumb", _childObjectId, _date] image:UIImageJPEGRepresentation(thumbImage, 0.7f)];
    
    NSMutableDictionary *options = [[NSMutableDictionary alloc]init];
    options[@"data"] = [[NSMutableDictionary alloc]initWithObjects:@[@"Increment"] forKeys:@[@"badge"]];
    [PushNotification sendInBackground:@"imageUpload" withOptions:options];
    PFObject *partner = (PFUser *)[Partner partnerUser];
    [NotificationHistory createNotificationHistoryWithType:@"imageUploaded" withTo:partner[@"userId"] withChild:_childObjectId withDate:[_date integerValue]];
    
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

-(CGRect) getUploadedImageFrame:(UIImage *) image
{
    float imageViewAspect = self.uploadViewController.defaultImageViewFrame.size.width/self.uploadViewController.defaultImageViewFrame.size.height;
    float imageAspect = image.size.width/image.size.height;
    
    // 横長バージョン
    // 枠より、画像の方が横長、枠の縦を縮める
    CGRect frame = self.uploadViewController.defaultImageViewFrame;
    if (imageAspect >= imageViewAspect){
        frame.size.height = frame.size.width/imageAspect;
        // 縦長バージョン
        // 枠より、画像の方が縦長、枠の横を縮める
    } else {
        frame.size.width = frame.size.height*imageAspect;
    }
    
    frame.origin.x = (self.view.frame.size.width - frame.size.width)/2;
    frame.origin.y = (self.view.frame.size.height - frame.size.height)/2;
    
    return frame;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
