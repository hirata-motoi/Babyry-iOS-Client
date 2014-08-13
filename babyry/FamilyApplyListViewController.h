//
//  FamilyApplyListViewController.h
//  babyry
//
//  Created by 平田基 on 2014/07/02.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "MBProgressHUD.h"

@interface FamilyApplyListViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>;
@property (weak, nonatomic) IBOutlet UITableView *familyApplyList;
@property (retain, atomic) NSArray *inviterUsers;
@property (retain, atomic) NSMutableDictionary *familyApplys;
@property (weak, nonatomic) IBOutlet UIView *noApplyMessageView;

@property MBProgressHUD *hud;

@end
