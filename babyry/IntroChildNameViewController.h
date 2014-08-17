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
@property (strong, nonatomic) IBOutlet UIView *editingView;
@property (strong, nonatomic) IBOutlet UITextField *childNameField1;
@property (strong, nonatomic) IBOutlet UITextField *childNameField2;
@property (strong, nonatomic) IBOutlet UITextField *childNameField3;
@property (strong, nonatomic) IBOutlet UITextField *childNameField4;
@property (strong, nonatomic) IBOutlet UITextField *childNameField5;
@property (strong, nonatomic) IBOutlet UILabel *childNameSendLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *textFieldContainerScrollView;
@property (weak, nonatomic) IBOutlet UIView *textFieldContainerView;

@property BOOL keyboradObserving;

@property BOOL isNotFirstTime;
//@property int currentChildNum;
@property int addableChildNum;

@property NSMutableArray *childProperties;

@property MBProgressHUD *hud;

@property UILabel *childLabel1;
@property UILabel *childLabel2;
@property UILabel *childLabel3;
@property UILabel *childLabel4;
@property UILabel *childLabel5;

@property UIButton *childButton1;
@property UIButton *childButton2;
@property UIButton *childButton3;
@property UIButton *childButton4;
@property UIButton *childButton5;

@property int removeTarget;

@end
