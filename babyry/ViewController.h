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
#import "PageViewController.h"

@interface ViewController : UIViewController <UIPageViewControllerDataSource>
@property (weak, nonatomic) IBOutlet UIButton *openGlobalSettingViewButton;

//- (IBAction)startWalkthrough:(id)sender;

@property (strong, nonatomic) NSArray *weekDateArray;
@property (strong, nonatomic) PFObject *currentUser;
@property (strong, nonatomic) PFObject *currentInstallation;
@property (strong, nonatomic) PageViewController *pageViewController;
@property NSMutableArray *childProperties;
@property (strong, nonatomic) NSArray *childArrayFoundFromParse;
@property NSMutableDictionary *childImages;

@property NSUInteger currentPageIndex;
@property int only_first_load;
@property MBProgressHUD *hud;
@property UIView *tagAlbumOperationView;

@end
