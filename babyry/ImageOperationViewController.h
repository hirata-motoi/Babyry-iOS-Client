//
//  ImageOperationViewController.h
//  babyry
//
//  Created by 平田基 on 2014/07/10.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@class UploadViewController;

@interface ImageOperationViewController : UIViewController<UIImagePickerControllerDelegate>

@property NSString *childObjectId;
@property NSString *month;
@property NSString *date;
@property UIImage *uploadedImage;
@property NSString *name;

@property UploadViewController *uploadViewController;

@property (strong, nonatomic) IBOutlet UIView *operationView;
@property (weak, nonatomic) IBOutlet UIButton *closeUploadViewControllerButton;
@property (weak, nonatomic) IBOutlet UILabel *yearMonthLabel;
@property (weak, nonatomic) IBOutlet UILabel *dayLabel;
@property (weak, nonatomic) IBOutlet UILabel *childNameLabel;
@property (weak, nonatomic) IBOutlet UIButton *openPhotoLibraryButton;
@property (weak, nonatomic) IBOutlet UIButton *openCommentViewButton;
@property (weak, nonatomic) IBOutlet UIButton *openTagViewButton;

@property UIView *commentView;
@property UIView *tagEditView;

@end
