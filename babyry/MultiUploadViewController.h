//
//  MultiUploadViewController.h
//  babyry
//
//  Created by kenjiszk on 2014/06/13.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface MultiUploadViewController : UIViewController<UICollectionViewDelegate, UICollectionViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

- (IBAction)multiUploadViewBackButton:(id)sender;
- (IBAction)multiUploadButton:(id)sender;
- (IBAction)testButton:(id)sender;

@property (weak, nonatomic) IBOutlet UILabel *multiUploadLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *multiUploadedImages;

@property NSString *childObjectId;
@property NSString *name;
@property NSArray *childImageArray;
@property NSString *month;
@property NSString *date;

@property float cellWidth;
@property float cellHeight;

@property UIImageView *bestShotLabelView;

@property int bestImageIndexAtFirst;

@end
