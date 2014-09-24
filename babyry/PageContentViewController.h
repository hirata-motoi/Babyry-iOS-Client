//
//  PageContentViewController.h
//  babyrydev
//
//  Created by kenjiszk on 2014/06/01.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "DragView.h"
#import "AWSS3Utils.h"
#import "MBProgressHUD.h"
#import <AudioToolbox/AudioServices.h>
#import "TagAlbumCollectionViewCell.h"
#import "TutorialNavigator.h"
#import "TutorialFamilyApplyIntroduceView.h"

@interface PageContentViewController : UIViewController<UICollectionViewDelegate, UICollectionViewDataSource, DragViewDelegate>
@property (weak, nonatomic) IBOutlet UICollectionView *pageContentCollectionView;

@property NSUInteger pageIndex;
@property NSMutableDictionary *childProperty;
@property NSString *childObjectId;

@property NSString *returnValueOfChildName;
@property NSString *returnValueOfChildBirthday;

@property NSMutableArray *bestFlagArray;
@property NSMutableArray *childImages;
@property NSMutableDictionary *childImagesIndexMap;
@property NSMutableArray *scrollPositionData;
@property CGFloat nextSectionHeight;
@property DragView *dragView;
@property BOOL dragging;
@property CGFloat dragViewUpperLimitOffset;
@property CGFloat dragViewLowerLimitOffset;
@property BOOL dragViewZoomed;
@property NSString *selfRole;
@property NSInteger dragCount;
@property NSMutableDictionary *imagesCountDic;

@property PFUser *currentUser;

@property int isFirstLoad;

@property UILabel *tutoSkipLabel;
@property BOOL isLoading;
@property NSDateComponents *dateComp;
@property NSMutableDictionary *notificationHistory;

- (void)drag:(DragView *)dragView;
- (NSMutableDictionary *)getYearMonthMap;
- (void)showAlertMessage;
- (void)addIntrodutionOfImageRequestView:(NSTimer *)timer;
- (void)openFamilyApply;
- (void)openFamilyApplyList;
-(void)setImages;

@property AWSServiceConfiguration *configuration;

@property MBProgressHUD *hud;

@property NSTimer *tm;

// for tutorial
@property TagAlbumCollectionViewCell *cellOfToday;
@property TutorialNavigator *tn;
@property TutorialFamilyApplyIntroduceView *familyApplyIntroduceView;

@end
