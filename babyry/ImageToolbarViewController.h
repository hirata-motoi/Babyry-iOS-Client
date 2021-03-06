//
//  ImageToolbarViewController.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/08/11.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "ImageCache.h"
#import "UploadViewController.h"
#import "MBProgressHUD.h"

@interface ImageToolbarViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIBarButtonItem *imageTrashView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *imageSaveView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *imageCommentView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *firstSpace;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *secondSpace;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *thirdSpace;

@property UploadViewController *uploadViewController;
@property UIView *commentView;
@property MBProgressHUD *hud;
@property BOOL openCommentView;
@property NSString *childObjectId;
@property NSString *date;

@end
