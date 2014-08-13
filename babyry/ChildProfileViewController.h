//
//  ChildProfileViewController.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/08/04.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ChildProfileEditViewController.h"

@interface ChildProfileViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, ChildProfileEditViewDelegate>

@property (strong, nonatomic) IBOutlet UITableView *childProfileTableView;

@property UITableViewCell *childNicknameCell;
@property UITableViewCell *childBirthdayCell;

@property NSString *childObjectId;
@property NSString *childName;
@property NSDate *childBirthday;
@property NSString *childBirthdayString;
@property PFObject *child;

@end
