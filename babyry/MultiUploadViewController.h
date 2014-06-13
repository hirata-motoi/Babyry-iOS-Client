//
//  MultiUploadViewController.h
//  babyry
//
//  Created by kenjiszk on 2014/06/13.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface MultiUploadViewController : UIViewController<UICollectionViewDelegate, UICollectionViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

- (IBAction)multiUploadViewBackButton:(id)sender;
- (IBAction)multiUploadButton:(id)sender;

@property (weak, nonatomic) IBOutlet UICollectionView *multiUploadedImages;

@property NSString *childObjectId;
@property NSArray *childImageArray;
@property NSString *month;
@property NSString *date;

@end
