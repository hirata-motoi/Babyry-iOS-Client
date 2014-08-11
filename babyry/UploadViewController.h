//
//  UploadViewController.h
//  babyrydev
//
//  Created by kenjiszk on 2014/06/04.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "ImageOperationViewController.h"

@interface UploadViewController : UIViewController<UIScrollViewDelegate>


@property (weak, nonatomic) IBOutlet UIImageView *uploadedImageView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property CGRect defaultImageViewFrame;
@property NSString *childObjectId;
@property NSString *month;
@property NSString *date;
@property UIImage *uploadedImage;
@property NSString *name;
@property NSString *promptText;

@property NSMutableArray *cellHeightArray;

@property BOOL keyboradObserving;

@property PFObject *imageInfo;
@property NSInteger tagAlbumPageIndex;
@property NSString *holdedBy; //このインスタンスを保持しているオブジェクトのクラス名
@property NSMutableDictionary *child;

// ImageOperationView使い回すため
@property UIView *operationView;
@property ImageOperationViewController *operationViewController;

@property AWSServiceConfiguration *configuration;

@property NSMutableArray *totalImageNum;
@property NSInteger currentRow;

@end
