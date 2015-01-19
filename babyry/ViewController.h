//
//  ViewController.h
//  babyrydev
//
//  Created by kenjiszk on 2014/05/30.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "PageContentViewController.h"
#import "MBProgressHUD.h"
#import "HeaderViewManager.h"
#import "ChildSwitchControlView.h"
#import "GlobalSettingViewController.h"

@interface ViewController : UIViewController<UINavigationControllerDelegate, HeaderViewManagerDelegate, ChildSwitchControlViewDelegate, GlobalSettingViewControllerDelegate>

@property (strong, nonatomic) NSArray *weekDateArray;
@property (strong, nonatomic) PFObject *currentUser;
@property (strong, nonatomic) PFObject *currentInstallation;
@property (strong, nonatomic) PageContentViewController *pageContentViewController;
@property (strong, nonatomic) NSArray *childArrayFoundFromParse;
@property NSMutableDictionary *childImages;

@property int only_first_load;
@property MBProgressHUD *hud;
@property UIView *tagAlbumOperationView;
@property HeaderViewManager *headerViewManager;
@property UIView *headerView;

- (void)showHeaderView:(NSString *)type;
- (void)hideHeaderView;
- (void)setupHeaderView;
- (void)showTutorialNavigator;
- (void)reloadPageContentViewController:(NSString *)childObjectId;
- (void)removeChildSwitchControlView;
- (void)viewDidAppear:(BOOL)animated;
- (void)openAddChild;

@end
