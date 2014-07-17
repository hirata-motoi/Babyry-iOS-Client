//
//  IntroChildNameViewController.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/07/10.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface IntroChildNameViewController : UIViewController
@property (strong, nonatomic) IBOutlet UIView *editingView;
@property (strong, nonatomic) IBOutlet UITextField *childNameField1;
@property (strong, nonatomic) IBOutlet UITextField *childNameField2;
@property (strong, nonatomic) IBOutlet UITextField *childNameField3;
@property (strong, nonatomic) IBOutlet UITextField *childNameField4;
@property (strong, nonatomic) IBOutlet UITextField *childNameField5;
@property (strong, nonatomic) IBOutlet UILabel *childNameSendLabel;
@property (strong, nonatomic) IBOutlet UILabel *backLabel;

@property BOOL keyboradObserving;

@property BOOL isNotFirstTime;
@property int currentChildNum;
@property int addableChildNum;

@end
