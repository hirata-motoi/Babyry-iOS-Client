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

@interface MultiUploadViewController : UIViewController<UICollectionViewDelegate, UICollectionViewDataSource, UINavigationControllerDelegate>

//- (IBAction)multiUploadViewBackButton:(id)sender;

@property (weak, nonatomic) IBOutlet UILabel *multiUploadLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *multiUploadedImages;
@property (strong, nonatomic) IBOutlet UILabel *explainLabel;

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

@property UIImageView *bestShotLabelView;

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

@end
