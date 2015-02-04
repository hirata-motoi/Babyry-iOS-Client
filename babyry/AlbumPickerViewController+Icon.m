//
//  AlbumPickerViewController+Icon.m
//  babyry
//
//  Created by hirata.motoi on 2015/01/13.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import "AlbumPickerViewController+Icon.h"
#import "AlbumPickerViewController.h"
#import "UIColor+Hex.h"
#import "ImageSelectToolView.h"
#import "ImageTrimming.h"
#import "ImageCache.h"
#import "ChildIconManager.h"
#import "ImageUtils.h"
#import "PushNotification.h"

@implementation AlbumPickerViewController_Icon {
    UIView *overlay;
    UIImage *originalImage;
    NSString *fileExtension;
}
static const float screenRate = 0.9;

- (void) logicViewDidLoad
{
    _albumPickerViewController.selectedImageCollectionView.hidden = YES;
    _albumPickerViewController.selectedImageBaseView.hidden = YES;
    _albumPickerViewController.sendImageLabel.hidden = YES;
    _albumPickerViewController.picNumLabel.hidden = YES;
}

// method名とは異なりsendしない。modalを表示するだけ
- (void) logicSendImageButton:(NSIndexPath *)indexPath
{
    [self openModalView:indexPath];
}

- (void)openModalView:(NSIndexPath *)indexPath
{
    ALAsset *asset = _albumPickerViewController.sectionImageDic[_albumPickerViewController.sectionDateByIndex[indexPath.section]][indexPath.row];
    ALAssetRepresentation *representation = [asset defaultRepresentation];
    NSURL *assetURL = [[asset valueForProperty:ALAssetPropertyURLs] objectForKey:[[asset defaultRepresentation] UTI]];
    fileExtension = [[assetURL path] pathExtension];
    originalImage = [UIImage imageWithCGImage:[representation fullResolutionImage] scale:[representation scale] orientation:(UIImageOrientation)[representation orientation]];
    
    // 縦横比計算
    CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
    
    CGFloat width;
    CGFloat height;
    CGFloat widthRatio = screenRect.size.width * screenRate / originalImage.size.width;
    CGFloat heightRatio = screenRect.size.height * screenRate / originalImage.size.height;
    CGFloat ratio = (widthRatio < heightRatio) ? widthRatio : heightRatio;
    width = originalImage.size.width * ratio;
    height = originalImage.size.height * ratio;
    
    CGRect rect = CGRectMake((screenRect.size.width - width)/2, (screenRect.size.height - height)/2, width, height);
    
    // modalを作る
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:rect];
    
    imageView.image = originalImage;
    overlay = [[UIView alloc]initWithFrame:screenRect];
    overlay.backgroundColor = [UIColor_Hex colorWithHexString:@"000000" alpha:0.6];
    [overlay addSubview:imageView];
    
    // tool view
    ImageSelectToolView *toolView = [ImageSelectToolView view];
    toolView.delegate = self;
    [overlay addSubview:toolView];
    CGRect toolViewRect = toolView.frame;
    toolViewRect.origin.x = 0;
    toolViewRect.origin.y = overlay.frame.size.height - toolView.frame.size.height;
    toolView.frame = toolViewRect;
    toolView.backgroundColor = [UIColor_Hex colorWithHexString:@"000000" alpha:0.6];
    
    overlay.alpha = 0.0f;
    [_albumPickerViewController.view addSubview:overlay];
    [UIView animateWithDuration:0.2f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         overlay.alpha = 1.0f;
                     }
                     completion:nil];
}

- (void)cancel
{
    [UIView animateWithDuration:0.2f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         overlay.alpha = 0.0f;
                     }
                     completion:^(BOOL finished) {
                        [overlay removeFromSuperview];
                     }];
}

- (void)submit
{
    UIImage *resizedImage = [ImageTrimming resizeImageForUpload:originalImage];
    UIImage *thumbnailImage = [ImageCache makeThumbNail:resizedImage];
    NSData *imageData = ([fileExtension isEqualToString:@"PNG"]) ? UIImagePNGRepresentation(thumbnailImage) : UIImageJPEGRepresentation(thumbnailImage, 0.7f);
    
    // こども追加の場合はnotification centerで通知
    if (!_albumPickerViewController.childObjectId) {
        NSDictionary *info = [[NSDictionary alloc]initWithObjectsAndKeys:imageData, @"imageData", nil];
        [[NSNotificationCenter defaultCenter]postNotificationName:@"childIconSelectedForNewChild" object:self userInfo:info];
    } else {
        [ChildIconManager updateChildIcon:imageData withChildObjectId:_albumPickerViewController.childObjectId];
        [self sendPushNotification];
    }
    
    [_albumPickerViewController dismissViewControllerAnimated:YES completion:nil];
    UINavigationController *naviController = (UINavigationController *)_albumPickerViewController.presentingViewController;
    [naviController popViewControllerAnimated:YES];
    
    // TODO navigationController内かどうかを判定して処理を分ける
    [_albumPickerViewController.delegate closeAlbumTable];
}

- (void)sendPushNotification
{
    NSMutableDictionary *transitionInfoDic = [[NSMutableDictionary alloc] init];
    transitionInfoDic[@"event"] = @"childIconChanged";
    NSMutableDictionary *options = [[NSMutableDictionary alloc]init];
    options[@"data"] = [[NSMutableDictionary alloc]
                        initWithObjects:@[transitionInfoDic, [NSNumber numberWithInt:1], @""]
                        forKeys:@[@"transitionInfo", @"content-available", @"sound"]];
    [PushNotification sendInBackground:@"childIconChanged" withOptions:options];
}

@end
