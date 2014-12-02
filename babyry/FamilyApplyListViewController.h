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
#import "FamilyApplyListCell.h"
#import "ChildFilterViewController.h"

@interface FamilyApplyListViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, FamilyApplyListCellDelegate, ChildFilterViewControllerDelegate>;
@property (weak, nonatomic) IBOutlet UITableView *familyApplyList;
@property (weak, nonatomic) IBOutlet UIView *noApplyMessageView;
@property (retain, atomic) NSArray *inviterUsers;
@property (retain, atomic) NSMutableDictionary *familyApplys;

- (void)admit:(NSInteger)index;
- (void)executeAdmit: (NSNumber *)indexNumber withChildFamilyMap:(NSMutableDictionary *)childFamilyMap;

@end
