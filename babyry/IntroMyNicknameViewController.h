//
//  IntroMyNicknameViewController.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/07/10.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface IntroMyNicknameViewController : UIViewController
@property (strong, nonatomic) IBOutlet UITextField *introMyNicknameField;
@property (strong, nonatomic) IBOutlet UILabel *introMyNicknameSendLabel;
@property (strong, nonatomic) IBOutlet UIView *editingView;
@property (strong, nonatomic) IBOutlet UISegmentedControl *selectSexController;
@property (strong, nonatomic) IBOutlet UIView *datePickerContainer;
@property (strong, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (strong, nonatomic) IBOutlet UILabel *birthdayLabel;

@property BOOL keyboradObserving;

@end
