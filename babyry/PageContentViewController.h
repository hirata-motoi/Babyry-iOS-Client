//
//  PageContentViewController.h
//  babyrydev
//
//  Created by kenjiszk on 2014/06/01.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
//#import "DragView.h"
#import "AWSCommon.h"
#import "MBProgressHUD.h"
#import <AudioToolbox/AudioServices.h>
#import "CalendarCollectionViewCell.h"
#import "TutorialNavigator.h"
#import "TutorialFamilyApplyIntroduceView.h"
#import "CollectionViewSectionHeader.h"

@protocol PageContentViewControllerDelegate <NSObject>
- (void) setGlobalMenuBadge:(int)badgeNumber;
- (void) updateNavitagionTitle:(NSString *)childName;
@end

@interface PageContentViewController : UIViewController<UICollectionViewDelegate, UICollectionViewDataSource, CollectionViewSectionHeaderDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *pageContentCollectionView;

@property (nonatomic,assign) id<PageContentViewControllerDelegate> delegate;

@property NSUInteger pageIndex;
@property NSString *childObjectId;

@property NSString *returnValueOfChildName;
@property NSString *returnValueOfChildBirthday;

@property NSMutableArray *bestFlagArray;
@property NSMutableArray *childImages;
@property NSMutableDictionary *childImagesIndexMap;
//@property NSMutableArray *scrollPositionData;
@property CGFloat nextSectionHeight;
@property BOOL dragging;
@property NSString *selfRole;
@property NSInteger dragCount;
@property NSMutableDictionary *imagesCountDic;

@property PFUser *currentUser;

@property int isFirstLoad;

@property UILabel *tutoSkipLabel;
@property BOOL isLoading;
@property NSDateComponents *dateComp;
@property BOOL isRotatingCells;
@property BOOL skippedReloadData;

- (NSMutableDictionary *)getYearMonthMap;
- (void)showAlertMessage;
//- (void)addIntroductionOfImageRequestView:(NSTimer *)timer;
//- (void)addIntroductionOfPageFlickView:(NSTimer *)timer;
- (void)openFamilyApply;
- (void)setImages;
- (void)showTutorialNavigator;
- (void)openFamilyApplyList;
- (void)openPartnerWait;
- (void)adjustChildImages;
- (void)showLoadingIcon;
- (void)hideLoadingIcon;
- (void)showIntroductionForFillingEmptyCells;
- (void)setupChildImagesIndexMap;
- (void)resetIconImageWithBlurWithCell;

@property AWSServiceConfiguration *configuration;

@property MBProgressHUD *hud;

@property NSTimer *tm;

@property UIRefreshControl *rc;

// for tutorial
@property CalendarCollectionViewCell *cellOfToday;
@property TutorialNavigator *tn;
@property UIView *familyApplyIntroduceView;
@property NSTimer *instructionTimer;


@property NSNotificationCenter *notificationCenter;

@property NSMutableDictionary *bestImageIds;

@property int badgeNumber;

@end
