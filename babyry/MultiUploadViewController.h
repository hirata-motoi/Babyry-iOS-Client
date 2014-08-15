//
//  MultiUploadViewController.h
//  babyry
//
//  Created by kenjiszk on 2014/06/13.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "CommentViewController.h"
#import "UIViewController+MJPopupViewController.h"
#import "MultiUploadAlbumTableViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface MultiUploadViewController : UIViewController<UICollectionViewDelegate, UICollectionViewDataSource, UINavigationControllerDelegate>

//- (IBAction)multiUploadViewBackButton:(id)sender;

@property (weak, nonatomic) IBOutlet UICollectionView *multiUploadedImages;
@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (strong, nonatomic) IBOutlet UIButton *bestShotReplyIcon;
@property (strong, nonatomic) IBOutlet UILabel *bestShotFixLimitLabel;

@property NSString *myRole;

@property NSString *childObjectId;
@property NSMutableDictionary *child;
@property NSString *name;
@property NSMutableArray *childImageArray;
@property NSMutableArray *childCachedImageArray;
@property NSMutableArray *childDetailImageArray;
@property NSString *month;
@property NSString *date;

@property float cellWidth;
@property float cellHeight;

@property UIImageView *selectedBestshotView;

@property int bestImageIndex;

@property int indexForCache;

@property NSTimer *myTimer;
@property BOOL needTimer;
@property int tmpCacheCount;
@property BOOL isTimperExecuting;

@property UIPageViewController *pageViewController;

@property int detailImageIndex;

@property PFUser *currentUser;

@property CommentViewController *commentViewController;
@property UIView *commentView;

@property int uploadUppeLimit;

@property AWSServiceConfiguration *configuration;
@property NSMutableDictionary *notificationHistoryByDay;

@property BOOL imageLoadComplete;

@end
