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
#import "ProfileEditViewController.h"

@interface ProfileViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate, ProfileEditViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *profileTableView;
@property NSInteger numberOfChild;
@property PFObject *partnerInfo;
@property UITableViewCell *nicknameCell;
@property NSInteger editedChildIndex;
@property UITableViewCell *emailCell;

- (void)changeNickname:(NSString *)nickname;
- (void)changeEmail:(NSString *)email;

@end
