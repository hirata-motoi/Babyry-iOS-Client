//
//  AlbumPickerViewController+Multi.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/11/05.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "AlbumPickerViewController+Multi.h"
#import "ImageTrimming.h"
#import "Tutorial.h"
#import "Logger.h"
#import "AlbumPickerViewController.h"
#import "ImageUploadInBackground.h"

@interface AlbumPickerViewController_Multi ()

@end

@implementation AlbumPickerViewController_Multi

- (void) logicViewDidLoad
{
    // Multiの場合、アップロード上限があるのでcurrentNum必須
    int currentNum = [[_albumPickerViewController.totalImageNum objectAtIndex:_albumPickerViewController.indexPath.row] intValue];
    _albumPickerViewController.picNumLabel.text = [NSString stringWithFormat:@"%d枚アップロード済み、残り%d枚", currentNum, 15 - currentNum];
    _albumPickerViewController.multiUploadMax = 3;
    // Config.m の方に入れますTODO
    PFQuery *upperLimit = [PFQuery queryWithClassName:@"Config"];
    [upperLimit whereKey:@"key" equalTo:@"multiUploadUpperLimit"];
    [upperLimit getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error){
        if (object) {
            _albumPickerViewController.multiUploadMax = [object[@"value"] intValue];
        }
    }];
    
    // 複数選択する為に必要
    _albumPickerViewController.checkedImageFragDic = [[NSMutableDictionary alloc] init];
    _albumPickerViewController.checkedImageArray = [[NSMutableArray alloc] init];
}

- (void) logicSendImageButton
{
    if ([ImageUploadInBackground getIsUploading]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"アップロード処理中です"
                                                        message:@"現在アップロード処理中ですので、しばらく時間をおいて次のアップロードを行ってください。"
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"OK", nil
                              ];
        [alert show];
        return;
    }

    if ([_albumPickerViewController.checkedImageArray count] + [[_albumPickerViewController.totalImageNum objectAtIndex:_albumPickerViewController.indexPath.row] intValue] > 15) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"上限数を超えています"
                                                        message:[NSString stringWithFormat:@"1日あたりアップロード可能なベストショット候補の写真は15枚です。既に%d枚アップロード済みです。アップロード済みの写真は拡大画面から削除も可能です", [[_albumPickerViewController.totalImageNum objectAtIndex:_albumPickerViewController.indexPath.row] intValue]]
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"OK", nil
                              ];
        [alert show];
        return;
    }
    
    if ([_albumPickerViewController.checkedImageArray count] == 0) {
        return;
    }
    
    _albumPickerViewController.hud.labelText = @"データ準備中";
    [_albumPickerViewController.hud hide:NO];
    
    // imageFileをフォアグランドで_uploadImageDataArrayに用意しておく
    // backgroundでセットしようとするとセット前の画像が解放されてしまうので
    _albumPickerViewController.uploadImageDataArray = [[NSMutableArray alloc] init];
    _albumPickerViewController.uploadImageDataTypeArray = [[NSMutableArray alloc] init];
    for (NSIndexPath *indexPath in _albumPickerViewController.checkedImageArray) {
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
        [_albumPickerViewController.uploadImageDataArray addObject:imageData];
        [_albumPickerViewController.uploadImageDataTypeArray addObject:imageType];
    }
    
    [_albumPickerViewController.hud hide:YES];
    if (_albumPickerViewController.totalImageNum) {
        int totalNum = [[_albumPickerViewController.totalImageNum objectAtIndex:_albumPickerViewController.indexPath.row] intValue] + [_albumPickerViewController.checkedImageArray count];
        [_albumPickerViewController.totalImageNum replaceObjectAtIndex:_albumPickerViewController.indexPath.row withObject:[NSNumber numberWithInt:totalNum]];
    }
    
    [ImageUploadInBackground setMultiUploadImageDataSet:_albumPickerViewController.childProperty
                              multiUploadImageDataArray:_albumPickerViewController.uploadImageDataArray
                          multiUploadImageDataTypeArray:_albumPickerViewController.uploadImageDataTypeArray
                                                   date:_albumPickerViewController.date
                                              indexPath:_albumPickerViewController.indexPath];
    NSNotification *n = [NSNotification notificationWithName:@"multiUploadImageInBackground" object:nil];
    [[NSNotificationCenter defaultCenter] postNotification:n];
    
    if ([[Tutorial currentStage].currentStage isEqualToString:@"uploadByUser"]) {
        [Tutorial forwardStageWithNextStage:@"uploadByUserFinished"];
    }
    
    // child icon
    [_albumPickerViewController setChildFirstIconWithImageData:_albumPickerViewController.uploadImageDataArray[0]]; // 決め
    
    [_albumPickerViewController dismissViewControllerAnimated:YES completion:NULL];
    
    //アルバム表示のViewも消す
    UINavigationController *naviController = (UINavigationController *)_albumPickerViewController.presentingViewController;
    [naviController popViewControllerAnimated:YES];
}

@end
