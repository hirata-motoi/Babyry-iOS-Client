//
//  AlbumPickerViewController.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/11/05.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "MultiUploadViewController.h"
#import "MBProgressHUD.h"

@protocol AlbumPickerViewControllerDelegate <NSObject>

- (void)closeAlbumTable;

@end

@interface AlbumPickerViewController : UIViewController<UICollectionViewDelegate, UICollectionViewDataSource>
@property (nonatomic, assign)id<AlbumPickerViewControllerDelegate>delegate;
@property (strong, nonatomic) IBOutlet UICollectionView *albumImageCollectionView;
@property (strong, nonatomic) IBOutlet UICollectionView *selectedImageCollectionView;

- (IBAction)sendImageButton:(id)sender;
- (IBAction)backButton:(id)sender;
- (void)setChildFirstIconWithImageData:(NSData *)imageData;

@property (strong, nonatomic) IBOutlet UIButton *backLabel;
@property (strong, nonatomic) IBOutlet UIButton *sendImageLabel;
@property (strong, nonatomic) IBOutlet UILabel *picNumLabel;


@property NSArray *alAssetsArr;
@property NSMutableArray *uploadImageDataArray;
@property NSMutableArray *uploadImageDataTypeArray;
@property NSMutableDictionary *checkedImageFragDic;
@property NSMutableArray *checkedImageArray;
@property NSMutableDictionary *sectionImageDic;
@property NSMutableArray *sectionDateByIndex;
@property NSMutableDictionary *childProperty;

@property NSString *month;
@property NSString *childObjectId;
@property NSString *date;
@property NSMutableArray *totalImageNum;
@property NSIndexPath *targetDateIndexPath;

@property MBProgressHUD *hud;

@property int multiUploadMax;

@property NSMutableDictionary *notificationHistoryByDay;

@property NSString *uploadType;
@property NSMutableDictionary *section;
@property UploadViewController *uploadViewController;

@end

