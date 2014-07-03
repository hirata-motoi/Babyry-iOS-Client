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

@interface MultiUploadPickerViewController : UIViewController<UICollectionViewDelegate, UICollectionViewDataSource>
@property (strong, nonatomic) IBOutlet UICollectionView *albumImageCollectionView;
@property (strong, nonatomic) IBOutlet UICollectionView *selectedImageCollectionView;

- (IBAction)sendImageButton:(id)sender;
- (IBAction)backButton:(id)sender;

@property NSArray *alAssetsArr;
@property NSMutableArray *checkedImageFragArray;
@property NSMutableArray *checkedImageArray;

@property NSString *month;
@property NSString *childObjectId;
@property NSString *date;

// navigate bar用
@property int maxPicNum;
@property int completePicNum;
@property MultiUploadViewController *multiUploadViewController;

@end