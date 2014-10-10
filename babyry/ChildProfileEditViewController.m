//
//  ChildProfileEditViewController.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/08/04.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ChildProfileEditViewController.h"
#import "DateUtils.h"
#import "Logger.h"

@interface ChildProfileEditViewController ()

@end

@implementation ChildProfileEditViewController
@synthesize delegate = _delegate;

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self makeEditField];
    
    UITapGestureRecognizer *coverViewTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(closeEditing)];
    coverViewTapGestureRecognizer.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:coverViewTapGestureRecognizer];
    
    UITapGestureRecognizer *childnameSaveGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(saveProfile)];
    childnameSaveGestureRecognizer.numberOfTapsRequired = 1;
    [_childNicknameSaveLabel addGestureRecognizer:childnameSaveGestureRecognizer];
    
    UITapGestureRecognizer *childBirthdaySaveGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(saveProfile)];
    childBirthdaySaveGestureRecognizer.numberOfTapsRequired = 1;
    [_childBirthdaySaveLabel addGestureRecognizer:childBirthdaySaveGestureRecognizer];
    
    _childBirthdayDatePicker.maximumDate = [NSDate date];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)closeEditing
{
    [self.view removeFromSuperview];
    [self dismissViewControllerAnimated:YES completion:nil];
    self.parentViewController.navigationItem.rightBarButtonItem = nil;
}

- (void)saveProfile
{
    // 保存
    PFQuery *childQuery = [PFQuery queryWithClassName:@"Child"];
    [childQuery whereKey:@"objectId" equalTo:_childObjectId];
    [childQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (error) {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in saveChildName : %@", error]];
            return;
        }
        if (!object) {
            [Logger writeOneShot:@"crit" message:@"Error in saveChildName : There is no object from childQuery"];
            return;
        }
        
        if ([_editTarget isEqualToString:@"name"]) {
            object[@"name"] = _childNicknameEditTextField.text;
            [_delegate changeChildNickname:_childNicknameEditTextField.text];
        } else if ([_editTarget isEqualToString:@"birthday"]) {
            object[@"birthday"] = [DateUtils setSystemTimezoneAndZero:_childBirthdayDatePicker.date];
            [_delegate changeChildBirthday:[DateUtils setSystemTimezoneAndZero:_childBirthdayDatePicker.date]];
        }
        [object saveInBackground];
    }];
    
    // 即反映のため、block外で。
    if ([_editTarget isEqualToString:@"name"]) {
        _child[@"name"] = _childNicknameEditTextField.text;
    } else if ([_editTarget isEqualToString:@"birthday"]) {
        _child[@"birthday"] = [DateUtils setSystemTimezoneAndZero:_childBirthdayDatePicker.date];
    }
    
    [self closeEditing];
}

- (void)makeEditField
{
    // 一旦全部消す
    for (UIView *view in self.view.subviews) {
        view.hidden = YES;
    }
    
    // table cell上に透明のformを出す
    if ([_editTarget isEqualToString:@"name"]) {
        _childNicknameCellContainer.hidden = NO;
        _childNicknameCellContainer.frame = _childNicknameCellRect;
        
        // textfield高さあわせ
        CGRect frame = _childNicknameEditTextField.frame;
        frame.size.height = _childNicknameCellRect.size.height;
        _childNicknameEditTextField.frame = frame;
        // 保存ラベルの高さあわせ
        frame = _childNicknameSaveLabel.frame;
        frame.size.height = _childNicknameCellRect.size.height;
        _childNicknameSaveLabel.frame = frame;
        
        //_childNicknameEditTextField.frame = _childNicknameCellRect;
        [_childNicknameEditTextField becomeFirstResponder]; // focusをあてる
        _childNicknameEditTextField.text = _child[@"name"];
    } else if ([_editTarget isEqualToString:@"birthday"]) {
        _childBirthdayDatePickerContainer.hidden = NO;
        CGRect frame = _childBirthdayDatePickerContainer.frame;
        frame.origin = _childBirthdayCellPoint;
        _childBirthdayDatePickerContainer.frame = frame;
        [_childBirthdayDatePicker becomeFirstResponder];
        
        if (!_child[@"birthday"] || [_child[@"birthday"] isEqualToDate:[NSDate distantFuture]]) {
            _childBirthdayDatePicker.date = _child[@"createdAt"] ? _child[@"createdAt"] : [DateUtils setSystemTimezone:[NSDate date]];
        } else {
            _childBirthdayDatePicker.date = _child[@"birthday"];
        }   
    }
}

@end
