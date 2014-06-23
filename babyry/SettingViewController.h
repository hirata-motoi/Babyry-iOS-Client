//
//  SettingViewController.h
//  babyry
//
//  Created by kenjiszk on 2014/06/23.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingViewController : UIViewController<UIAlertViewDelegate>
- (IBAction)settingViewBackButton:(id)sender;
- (IBAction)settingViewSaveButton:(id)sender;
@property (strong, nonatomic) IBOutlet UIScrollView *settingScrollView;
@property (strong, nonatomic) IBOutlet UIImageView *settingMyImageView;
@property (strong, nonatomic) IBOutlet UITextField *settingMyNicknameField;
@property (strong, nonatomic) IBOutlet UITextField *settingChildNameField;
@property (strong, nonatomic) IBOutlet UILabel *settingChildBirthdayLabel;
- (IBAction)datePickerSaveButton:(id)sender;
@property (strong, nonatomic) IBOutlet UIButton *datePickerSaveLabel;
@property (strong, nonatomic) IBOutlet UIDatePicker *settingDatePicker;

@property NSString *childObjectId;
@property NSString *childName;
@property NSDate *childBirthday;

@property int first_open_picker;

@property int no_birthday;

@end
