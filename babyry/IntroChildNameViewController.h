//
//  IntroChildNameViewController.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/07/10.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "MBProgressHUD.h"

@interface IntroChildNameViewController : UIViewController

@property BOOL keyboradObserving;


@property NSMutableArray *childProperties;

@property MBProgressHUD *hud;

@property int removeTarget;

@property BOOL isBabyryExist;

@property (strong, nonatomic) IBOutlet UITextField *childNameField;
@property (strong, nonatomic) IBOutlet UISegmentedControl *childSexSegment;
@property (strong, nonatomic) IBOutlet UILabel *childAddButton;
@property (strong, nonatomic) IBOutlet UILabel *birthdayLabel;

@property (strong, nonatomic) IBOutlet UIView *datePickerContainer;
@property (strong, nonatomic) IBOutlet UIDatePicker *datePicker;

@property (strong, nonatomic) IBOutlet UIScrollView *childListContainer;

@end
