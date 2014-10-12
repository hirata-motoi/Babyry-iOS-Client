//
//  GlobalSettingViewController.h
//  babyry
//
//  Created by 平田基 on 2014/07/08.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <QuartzCore/QuartzCore.h>
#import "MBProgressHUD.h"

@interface GlobalSettingViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *settingTableView;
@property UISegmentedControl *roleControl;
@property PFObject *partnerInfo;
@property UIViewController *viewController;
@property NSString *emailVerified;

// for tutorial
@property UITableViewCell *partSwitchCell;
@property UITableViewCell *addChildCell;

@end
