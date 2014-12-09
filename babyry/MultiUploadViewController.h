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
#import <QuartzCore/QuartzCore.h>
#import "MBProgressHUD.h"
#import "PageContentViewController.h"

@interface MultiUploadViewController : UIViewController<UICollectionViewDelegate, UICollectionViewDataSource, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *multiUploadedImages;
@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (strong, nonatomic) IBOutlet UIButton *bestShotReplyIcon;
@property (strong, nonatomic) IBOutlet UILabel *bestShotFixLimitLabel;
@property (strong, nonatomic) IBOutlet UILabel *instructionLabel;

@property NSString *myRole;

@property NSString *childObjectId;
@property NSMutableArray *childImageArray;
@property NSMutableArray *childCachedImageArray;
@property NSMutableArray *childDetailImageArray;
@property NSString *month;
@property NSString *date;

@property float cellWidth;
@property float cellHeight;

@property UIImageView *selectedBestshotView;

@property NSString *bestImageId;

//@property int indexForCache;

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

@property MBProgressHUD *hud;

@property NSMutableArray *totalImageNum;
@property NSIndexPath *indexPath;

// for tutorial
@property UIView *firstCellUnselectedBestShotView;

- (void)showTutorialNavigator;
- (void)removeNavigationView;
- (void)forwardNextTutorial;
//- (void) dispatchForPushReceivedTransition;

// バッチの更新時にreloadをかけるため
@property (weak) PageContentViewController *pCVC;
@end
