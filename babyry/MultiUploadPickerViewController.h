//
//  MultiUploadPickerViewController.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/07/02.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "MultiUploadViewController.h"
#import "MBProgressHUD.h"

@interface MultiUploadPickerViewController : UIViewController<UICollectionViewDelegate, UICollectionViewDataSource>
@property (strong, nonatomic) IBOutlet UICollectionView *albumImageCollectionView;
@property (strong, nonatomic) IBOutlet UICollectionView *selectedImageCollectionView;

- (IBAction)sendImageButton:(id)sender;
- (IBAction)backButton:(id)sender;

@property NSArray *alAssetsArr;
@property NSMutableArray *checkedImageFragArray;
@property NSMutableArray *checkedImageArray;
@property NSMutableArray *uploadImageDataArray;

@property NSString *month;
@property NSString *childObjectId;
@property NSString *date;

@property int currentCachedImageNum;

@property MBProgressHUD *hud;

@end
