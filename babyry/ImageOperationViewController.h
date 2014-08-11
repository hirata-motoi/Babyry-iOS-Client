//
//  ImageOperationViewController.h
//  babyry
//
//  Created by 平田基 on 2014/07/10.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <Parse/Parse.h>
#import "AWSS3Utils.h"

@class UploadViewController;

@interface ImageOperationViewController : UIViewController<UIImagePickerControllerDelegate>

@property NSString *childObjectId;
@property NSString *month;
@property NSString *date;
@property UIImage *uploadedImage;
@property NSString *name;

@property UploadViewController *uploadViewController;

@property (strong, nonatomic) IBOutlet UIView *operationView;
@property (weak, nonatomic) IBOutlet UINavigationBar *navbar;
@property (weak, nonatomic) IBOutlet UINavigationItem *navbarItem;
@property (weak, nonatomic) IBOutlet UIView *statusBarCoverView;

@property UIView *commentView;
@property UIView *tagEditView;
@property NSString *holdedBy;
@property UIView *toolbarView;

@property PFObject *imageInfo;
// isPreloadの場合キャッシュのサムネイルを表示するだけなのでコメントViewは表示させない
@property BOOL isPreload;

@property AWSServiceConfiguration *configuration;

@property BOOL directOpenLibrary;

@end
