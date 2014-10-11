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

@property (strong, nonatomic) IBOutlet UIButton *backLabel;
@property (strong, nonatomic) IBOutlet UIButton *sendImageLabel;
@property (strong, nonatomic) IBOutlet UILabel *picNumLabel;


@property NSArray *alAssetsArr;
@property NSMutableArray *checkedImageFragArray;
@property NSMutableArray *checkedImageArray;
@property NSMutableArray *uploadImageDataArray;
@property NSMutableArray *uploadImageDataTypeArray;
//@property NSMutableDictionary *child;

@property NSString *month;
@property NSString *childObjectId;
@property NSString *date;
@property NSMutableArray *totalImageNum;
@property NSIndexPath *indexPath;

@property MBProgressHUD *hud;

@property AWSServiceConfiguration *configuration;
@property NSInteger uploadedImageCount;

@property int multiUploadMax;

@end
