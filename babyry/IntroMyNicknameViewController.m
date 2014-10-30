//
//  IntroMyNicknameViewController.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/07/10.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "IntroMyNicknameViewController.h"
#import "MBProgressHUD.h"
#import "Logger.h"
#import "PartnerInvitedEntity.h"
#import "PartnerApply.h"
#import "DateUtils.h"
#import "CloseButtonView.h"
#import "Tutorial.h"
#import "ImageCache.h"
#import "PushNotification.h"
#import "TmpUser.h"

@interface IntroMyNicknameViewController ()

@end

@implementation IntroMyNicknameViewController {
    BOOL selectedBirthday;
}

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

    _introMyNicknameSendLabel.tag = 2;
    _introMyNicknameSendLabel.layer.cornerRadius = 2.0f;
    
    UITapGestureRecognizer *stgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    stgr.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:stgr];
    
    UITapGestureRecognizer *stgr2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    stgr2.numberOfTapsRequired = 1;
    [_introMyNicknameSendLabel addGestureRecognizer:stgr2];
    
    UITapGestureRecognizer *stgr3 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openDatePicker)];
    stgr3.numberOfTapsRequired = 1;
    [_birthdayLabel addGestureRecognizer:stgr3];
    
    // frame for UILabel
    _requiredNickName.layer.borderColor = [UIColor redColor].CGColor;
    _requiredNickName.layer.borderWidth = 0.6;
    _optionalBirthday.layer.borderColor = [UIColor darkGrayColor].CGColor;
    _optionalBirthday.layer.borderWidth = 0.6;
    _optionalSex.layer.borderColor = [UIColor darkGrayColor].CGColor;
    _optionalSex.layer.borderWidth = 0.6;
    
    // set date
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* components = [[NSDateComponents alloc] init];
    components.year = 1984;
    components.month = 1;
    components.day = 1;
    
    _datePicker.date = [calendar dateFromComponents:components];
    [self resetBirthday];

    _datePickerContainer.hidden = YES;
    
    _datePicker.maximumDate = [NSDate date];
    [_datePicker addTarget:self action:@selector(action:forEvent:) forControlEvents:UIControlEventValueChanged];
    selectedBirthday = NO;
    [_birthdayResetButton addTarget:self action:@selector(resetBirthday) forControlEvents:UIControlEventTouchUpInside];
    
    // logout button
    [self setupLogoutButton];
    
    // sex
    [self resetSex];
    [_sexResetButton addTarget:self action:@selector(resetSex) forControlEvents:UIControlEventTouchUpInside];
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
    
    // Start observing
    if (!_keyboradObserving) {
        NSNotificationCenter *center;
        center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [center addObserver:self selector:@selector(keybaordWillHide:) name:UIKeyboardWillHideNotification object:nil];
        _keyboradObserving = YES;
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

- (void)keyboardWillShow:(NSNotification*)notification
{
    _datePickerContainer.hidden = YES;
    
    // Get userInfo
    NSDictionary *userInfo;
    userInfo = [notification userInfo];
    
    NSTimeInterval duration;
    UIViewAnimationCurve animationCurve;
    void (^animations)(void);
    duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    animations = ^(void) {
    };
    [UIView animateWithDuration:duration delay:0.0 options:(animationCurve << 16) animations:animations completion:nil];
}

- (void)keybaordWillHide:(NSNotification*)notification
{
    // Get userInfo
    NSDictionary *userInfo;
    userInfo = [notification userInfo];
    
    NSTimeInterval duration;
    UIViewAnimationCurve animationCurve;
    void (^animations)(void);
    duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    animations = ^(void) {
    };
    [UIView animateWithDuration:duration delay:0.0 options:(animationCurve << 16) animations:animations completion:nil];
}

-(void)handleSingleTap:(id) sender
{
    if ([sender view].tag == 2) {
        if (!_introMyNicknameField.text || [_introMyNicknameField.text isEqualToString:@""]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ニックネームを入力してください"
                                                            message:@""
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"OK", nil
                                  ];
            [alert show];
        } else {
            
            PFObject *user = [PFUser currentUser];
            user[@"nickName"] = _introMyNicknameField.text;
           
            // 未選択の場合はUISegmentedControlNoSegment
            if (_selectSexController.selectedSegmentIndex == 0) {
                user[@"sex"] = @"male";
            } else if (_selectSexController.selectedSegmentIndex == 1) {
                user[@"sex"] = @"female";
            }
           
            if (selectedBirthday) {
                user[@"birthday"] = [DateUtils setSystemTimezoneAndZero:_datePicker.date];
            }
            
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.labelText = @"データ保存中";

            [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (error) {
                    [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in saving username and sex : %@", error]];
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"データの保存に失敗しました"
                                                                    message:@"ネットワークエラーが発生しました。もう一度お試しください。"
                                                                   delegate:nil
                                                          cancelButtonTitle:nil
                                                          otherButtonTitles:@"OK", nil
                                          ];
                    [alert show];
                    [hud hide:YES];
                    return;
                }
                
                [PartnerApply registerApplyList];
                [hud hide:YES];
                if ([self.navigationController isViewLoaded]) {
                    [self.navigationController popToRootViewControllerAnimated:YES];
                } else {
                    [self dismissViewControllerAnimated:YES completion:nil];
                }
            }];
        }
    } else {
        _datePickerContainer.hidden = YES;
        [self.view endEditing:YES];
    }
}

- (void)openDatePicker
{
    [self.view endEditing:YES];
    _datePickerContainer.hidden = NO;
}

- (void)action:(id)sender forEvent:(UIEvent *)event
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"yyyy/MM/dd";
    _birthdayLabel.text = [df stringFromDate:_datePicker.date];
    selectedBirthday = YES;
}

- (void)resetBirthday
{
    _birthdayLabel.text = @"----/--/--";
    selectedBirthday = NO;
}

- (void)resetSex
{
    _selectSexController.selectedSegmentIndex = UISegmentedControlNoSegment;
}

- (void)setupLogoutButton
{
    CloseButtonView *view = [CloseButtonView view];
    CGRect rect = view.frame;
    rect.origin.x = 10;
    rect.origin.y = 30;
    view.frame = rect;
    
    UITapGestureRecognizer *logoutGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(logout)];
    logoutGesture.numberOfTapsRequired = 1;
    [view addGestureRecognizer:logoutGesture];
    
    [self.view addSubview:view];
}

- (void)logout
{
    [TmpUser removeTmpUser];
    [self dismissViewControllerAnimated:YES completion:nil];
    [Tutorial removeTutorialStage];
    [ImageCache removeAllCache];
    [PartnerApply removePartnerInviteFromCoreData];
    [PartnerApply removePartnerInvitedFromCoreData];
    [PushNotification removeSelfUserIdFromChannels:^(){
        [PFUser logOut];
    }];
}

@end
