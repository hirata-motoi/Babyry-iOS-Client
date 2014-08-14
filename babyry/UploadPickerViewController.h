//
//  UploadPickerViewController.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/08/11.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "UploadViewController.h"

@interface UploadPickerViewController : UIViewController<UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property UploadViewController *uploadViewController;

@property NSString *childObjectId;
@property NSString *month;
@property NSString *date;

@property AWSServiceConfiguration *configuration;

@property NSMutableArray *totalImageNum;
@property NSIndexPath *indexPath;
@property NSMutableDictionary *section;
@property NSMutableDictionary *child;

@end
