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
#import "ChildProperties.h"

@interface ChildProfileEditViewController ()

@end

@implementation ChildProfileEditViewController
@synthesize delegate = _delegate;

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _childProperty = [ChildProperties getChildProperty:_childObjectId];
    
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
    NSMutableDictionary *params = [self createSaveParams];
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
        
        for (NSString *key in [params allKeys]) {
            if (params[key] == [NSNull null]) {
                [object removeObjectForKey:key];
            } else {
                object[key] = params[key];
            }
        }
        [object saveInBackground];
    }];
    
    // 即反映のため、block外で。
    [ChildProperties updateChildPropertyWithObjectId:_childObjectId withParams:params];
    _childProperty = [ChildProperties getChildProperty:_childObjectId];
    
    if ([_editTarget isEqualToString:@"name"]) {
        _childProperty[@"name"] = _childNicknameEditTextField.text;
        [_delegate changeChildNickname:_childNicknameEditTextField.text];
    } else if ([_editTarget isEqualToString:@"birthday"]) {
        _childProperty[@"birthday"] = [DateUtils setSystemTimezoneAndZero:_childBirthdayDatePicker.date];
        [_delegate changeChildBirthday:[DateUtils setSystemTimezoneAndZero:_childBirthdayDatePicker.date]];
    }
    
    [self closeEditing];
}

- (NSMutableDictionary *)createSaveParams
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
   if ([_editTarget isEqualToString:@"name"]) {
       params[@"name"] = _childNicknameEditTextField.text;
       return params;
       
   } else if ([_editTarget isEqualToString:@"birthday"]) {
       params[@"birthday"] = [DateUtils setSystemTimezoneAndZero:_childBirthdayDatePicker.date];
      
       NSDateComponents *comps = [DateUtils dateCompsFromDate:_childBirthdayDatePicker.date];
       NSNumber *birthdayNumber = [NSNumber numberWithInteger:[[NSString stringWithFormat:@"%ld%02ld%02ld", comps.year, comps.month, comps.day] integerValue]];
       
       if (_childProperty[@"calendarStartDate"]) {
           if ([_childProperty[@"calendarStartDate"] compare:birthdayNumber] == NSOrderedAscending) {
               // 変更後の誕生日の方が未来なので、今後のcalendarはcalendarStartDateの日付が優先される
               // 要はcalendarStartDateはそのまま
           } else {
               // 変更後誕生日の方が過去なので、今後のcalendarは誕生日から開始となる。
               // つまりcalendarStartDateは不要となるので空にする
               params[@"calendarStartDate"] = [NSNull null];
           }
       }
       return params;
   }
    return nil;
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
        _childNicknameEditTextField.text = _childProperty[@"name"];
    } else if ([_editTarget isEqualToString:@"birthday"]) {
        _childBirthdayDatePickerContainer.hidden = NO;
        CGRect frame = _childBirthdayDatePickerContainer.frame;
        frame.origin = _childBirthdayCellPoint;
        _childBirthdayDatePickerContainer.frame = frame;
        [_childBirthdayDatePicker becomeFirstResponder];
        
        if (!_childProperty[@"birthday"] || [_childProperty[@"birthday"] isEqualToDate:[NSDate distantFuture]]) {
            _childBirthdayDatePicker.date = _childProperty[@"createdAt"] ? _childProperty[@"createdAt"] : [DateUtils setSystemTimezone:[NSDate date]];
        } else {
            _childBirthdayDatePicker.date = _childProperty[@"birthday"];
        }   
    }
}

@end
