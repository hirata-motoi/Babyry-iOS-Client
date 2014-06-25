//
//  SettingViewController.m
//  babyry
//
//  Created by kenjiszk on 2014/06/23.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "SettingViewController.h"
#import <Parse/Parse.h>

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
    _settingMyImageView.image = [UIImage imageNamed:@"NoImage"];
    _settingMyNicknameField.text = [[PFUser currentUser] objectForKey:@"nickName"];
    _settingChildNameField.text = _childName;
    NSLog(@"test : %@", _childBirthday);
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
    UITapGestureRecognizer *singleTapGestureRecognizer2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openDatePicker:)];
    singleTapGestureRecognizer2.numberOfTapsRequired = 1;
    [_settingChildBirthdayLabel addGestureRecognizer:singleTapGestureRecognizer2];

    _settingDatePicker.hidden = YES;
    _settingDatePicker.backgroundColor = [UIColor whiteColor];
    _datePickerSaveLabel.hidden = YES;
    _first_open_picker = 1;
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
    PFUser *currentUser = [PFUser currentUser];
    if (![currentUser[@"nickName"] isEqualToString:_settingMyNicknameField.text]) {
        currentUser[@"nickName"] = _settingMyNicknameField.text;
        [currentUser saveInBackground];
    }
    
    PFQuery *childQuery = [PFQuery queryWithClassName:@"Child"];
    [childQuery whereKey:@"objectId" equalTo:_childObjectId];
    [childQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!error && object) {
            if (![object[@"name"] isEqualToString:_settingChildNameField.text]) {
                object[@"name"] = _settingChildNameField.text;
                [object saveInBackground];
            }
            if(![object[@"birthday"] isEqualToDate:_settingDatePicker.date]) {
                object[@"birthday"] = _settingDatePicker.date;
                [object saveInBackground];
            }
        }
    }];
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
    CGRect frame = _settingDatePicker.frame;
    frame.origin.y = self.view.frame.size.height;
    _settingDatePicker.frame = frame;
    _settingDatePicker.hidden = NO;
    _datePickerSaveLabel.hidden = NO;
    if (_first_open_picker == 1) {
        if (_no_birthday != 1) {
            _settingDatePicker.date = _childBirthday;
            _first_open_picker = 0;
        }
    }
    
    // TODO アニメーションにしたい　したからにゅっと出る感じで
    NSTimeInterval duration;
    UIViewAnimationCurve animationCurve;
    void (^animations)(void);
    frame.origin.y = frame.origin.y - _settingDatePicker.frame.size.height - 50;
    animations = ^(void) {
        _settingDatePicker.frame = frame;
    };
    [UIView animateWithDuration:duration delay:0.0 options:(animationCurve << 16) animations:animations completion:nil];
}

- (IBAction)datePickerSaveButton:(id)sender {
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"yyyy/MM/dd";
    _settingChildBirthdayLabel.text = [df stringFromDate:_settingDatePicker.date];
    
    _settingDatePicker.hidden = YES;
    _datePickerSaveLabel.hidden = YES;
}

@end
