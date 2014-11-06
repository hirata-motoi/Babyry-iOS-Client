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
    
    [delegate disableNotificationHistory];
    
    int __block saveCount = 0;
    
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
        
        PFObject *childImage = [PFObject objectWithClassName:[NSString stringWithFormat:@"ChildImage%ld", (long)[_albumPickerViewController.childProperty[@"childImageShardIndex"] integerValue]]];
        // tmpData = @"TRUE" にセットしておく画像はあとからあげる
        childImage[@"date"] = [NSNumber numberWithInteger:[_albumPickerViewController.date integerValue]];
        childImage[@"imageOf"] = _albumPickerViewController.childObjectId;
        childImage[@"bestFlag"] = @"unchoosed";
        childImage[@"isTmpData"] = @"TRUE";
        [childImage saveInBackgroundWithBlock:^(BOOL succeed, NSError *error){
            saveCount++;
            if ([_albumPickerViewController.checkedImageArray count] == saveCount) {
                [_albumPickerViewController.hud hide:YES];
                if (_albumPickerViewController.totalImageNum) {
                    [_albumPickerViewController.totalImageNum replaceObjectAtIndex:_albumPickerViewController.indexPath.row withObject:[NSNumber numberWithInt:saveCount]];
                }
                _albumPickerViewController.uploadedImageCount = 0; // initialize
                
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
                [_albumPickerViewController dismissViewControllerAnimated:YES completion:NULL];
                
                //アルバム表示のViewも消す
                UINavigationController *naviController = (UINavigationController *)_albumPickerViewController.presentingViewController;
                [naviController popViewControllerAnimated:YES];
            }
            if (error) {
                [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in saveTmpData in Parse : %@", error]];
            }
        }];
    }
}

@end
