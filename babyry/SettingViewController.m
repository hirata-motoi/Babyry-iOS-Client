//
//  SettingViewController.m
//  babyry
//
//  Created by kenjiszk on 2014/06/23.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "SettingViewController.h"
#import <Parse/Parse.h>
#import "DateUtils.h"

@interface SettingViewController ()

@end

@implementation SettingViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _settingAgeLabel.text = @"";
    _settingPicturesLabel.text = @"";
    if (_childBirthday) {
        _settingDatePicker.date = _childBirthday;
    } else {
        _settingDatePicker.date = [NSDate distantFuture];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    // super
    [super viewWillAppear:animated];
    
    UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    singleTapGestureRecognizer.numberOfTapsRequired = 1;
    [_settingScrollView addGestureRecognizer:singleTapGestureRecognizer];
    
    // default settings
    _settingChildNameField.text = _childName;
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"yyyy/MM/dd";
    NSDateFormatter *dfYear = [[NSDateFormatter alloc] init];
    dfYear.dateFormat = @"yyyy";
    _no_birthday = 0;
    if ([[dfYear stringFromDate:_childBirthday] intValue] > 3000) {
        _settingChildBirthdayLabel.text = @"----/--/--";
        _no_birthday = 1;
    } else {
        _settingChildBirthdayLabel.text = [df stringFromDate:_childBirthday];
    }
    
    _editChildBirthdayLabel.layer.cornerRadius = _editChildBirthdayLabel.frame.size.width/2;
    _datePickerSaveLabel.layer.cornerRadius = _datePickerSaveLabel.frame.size.width/2;
    _datePickerSaveLabel.layer.borderWidth = 2;
    _datePickerSaveLabel.layer.borderColor = [UIColor orangeColor].CGColor;
    
    UITapGestureRecognizer *singleTapGestureRecognizer2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openDatePicker:)];
    singleTapGestureRecognizer2.numberOfTapsRequired = 1;
    [_editChildBirthdayLabel addGestureRecognizer:singleTapGestureRecognizer2];

    _settingDatePicker.hidden = YES;
    _settingDatePicker.backgroundColor = [UIColor whiteColor];
    _datePickerSaveLabel.hidden = YES;
    _first_open_picker = 1;
    
    NSDate *today = [DateUtils setSystemTimezoneAndZero:[NSDate date]];
    float age = [today timeIntervalSinceDate:[DateUtils setSystemTimezoneAndZero:_settingDatePicker.date]]/60/60/24;
    if ((int)(age + 1) > 0) {
        _settingAgeLabel.text = [NSString stringWithFormat:@"%d日目", (int)(age + 1)];
    } else {
        _settingAgeLabel.text = [NSString stringWithFormat:@" - 日目"];        
    }
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

- (IBAction)settingViewBackButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)settingViewSaveButton:(id)sender {
    NSLog(@"save in background");
    
    PFQuery *childQuery = [PFQuery queryWithClassName:@"Child"];
    [childQuery whereKey:@"objectId" equalTo:_childObjectId];
    [childQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!error && object) {
            if (![object[@"name"] isEqualToString:_settingChildNameField.text]) {
                object[@"name"] = _settingChildNameField.text;
                [object saveInBackground];
            }
            if(![object[@"birthday"] isEqualToDate:[DateUtils setSystemTimezoneAndZero:_settingDatePicker.date]]) {
                object[@"birthday"] = [DateUtils setSystemTimezoneAndZero:_settingDatePicker.date];
                [object saveInBackground];
            }
        }
    }];
    
    _pViewController.returnValueOfChildName = _settingChildNameField.text;
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

-(void)handleSingleTap:(id) sender
{
    [self.view endEditing:YES];
}

-(void)openDatePicker:(id)selector
{
    NSLog(@"openDatePicker");

    _settingDatePicker.datePickerMode = UIDatePickerModeDate;
    _settingDatePicker.hidden = NO;
    _datePickerSaveLabel.hidden = NO;
}

- (IBAction)datePickerSaveButton:(id)sender {
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"yyyy/MM/dd";
    _settingChildBirthdayLabel.text = [df stringFromDate:_settingDatePicker.date];
    
    _settingDatePicker.hidden = YES;
    _datePickerSaveLabel.hidden = YES;
}

@end
