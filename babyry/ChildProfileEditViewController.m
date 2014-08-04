//
//  ChildProfileEditViewController.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/08/04.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ChildProfileEditViewController.h"
#import "DateUtils.h"

@interface ChildProfileEditViewController ()

@end

@implementation ChildProfileEditViewController
@synthesize delegate = _delegate;

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UITapGestureRecognizer *coverViewTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(closeEditing)];
    coverViewTapGestureRecognizer.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:coverViewTapGestureRecognizer];
    
    // table cell上に透明のformを出す
    if ([_editTarget isEqualToString:@"name"]) {
        NSLog(@"edit name");
        _childNicknameEditTextField.frame = _childNicknameCellRect;
        [_childNicknameEditTextField becomeFirstResponder]; // focusをあてる
        _childNicknameEditTextField.hidden = NO;
        _childBirthdayDatePicker.hidden = YES;
    } else if ([_editTarget isEqualToString:@"birthday"]) {
        NSLog(@"edit birthday");
        CGRect frame = _childBirthdayDatePickerContainer.frame;
        frame.origin = _childBirthdayCellPoint;
        _childBirthdayDatePickerContainer.frame = frame;
        [_childBirthdayDatePicker becomeFirstResponder];
        _childNicknameEditTextField.hidden = YES;
        _childBirthdayDatePicker.hidden = NO;
        _childBirthdayDatePicker.date = _childBirthday;
    }
    
    UIBarButtonItem *saveNameButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonItemStylePlain target:self action:@selector(saveChildName)];
    self.parentViewController.navigationItem.rightBarButtonItem = saveNameButton;
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

- (void)saveChildName
{
    // 保存
    PFQuery *childQuery = [PFQuery queryWithClassName:@"Child"];
    [childQuery whereKey:@"objectId" equalTo:_childObjectId];
    [childQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!error && object) {
            if ([_editTarget isEqualToString:@"name"]) {
                object[@"name"] = _childNicknameEditTextField.text;
                [_delegate changeChildNickname:_childNicknameEditTextField.text];
            } else if ([_editTarget isEqualToString:@"birthday"]) {
                NSLog(@"comparison date %@ %@", object[@"birthday"], [DateUtils setSystemTimezoneAndZero:_childBirthdayDatePicker.date]);
                if(![object[@"birthday"] isEqualToDate:[DateUtils setSystemTimezoneAndZero:_childBirthdayDatePicker.date]]) {
                    object[@"birthday"] = [DateUtils setSystemTimezoneAndZero:_childBirthdayDatePicker.date];
                }
                [_delegate changeChildBirthday:[DateUtils setSystemTimezoneAndZero:_childBirthdayDatePicker.date]];
            }
            [object saveInBackground];
        }
    }];
    
    [self closeEditing];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
