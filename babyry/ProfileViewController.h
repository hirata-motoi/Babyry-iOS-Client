//
//  ProfileViewController.h
//  babyry
//
//  Created by 平田基 on 2014/07/16.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <QuartzCore/QuartzCore.h>
#import "NicknameEditViewController.h"

@interface ProfileViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, NicknameEditViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *profileTableView;
@property NSInteger numberOfChild;
@property PFObject *partnerInfo;
@property NSMutableArray *childProperties;
@property UITableViewCell *nicknameCell;
@property NSInteger editedChildIndex;

- (void)changeNickname:(NSString *)nickname;

@end
