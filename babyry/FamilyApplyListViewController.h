//
//  FamilyApplyListViewController.h
//  babyry
//
//  Created by 平田基 on 2014/07/02.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface FamilyApplyListViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>;
@property (weak, nonatomic) IBOutlet UIButton *closeFamilyApplyListButton;
@property (weak, nonatomic) IBOutlet UITableView *familyApplyList;
@property (retain, atomic) NSArray *inviterUsers;

@end
