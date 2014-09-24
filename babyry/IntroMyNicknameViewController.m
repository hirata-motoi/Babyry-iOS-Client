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

@interface IntroMyNicknameViewController ()

@end

@implementation IntroMyNicknameViewController

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
    
    UITapGestureRecognizer *stgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    stgr.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:stgr];
    
    UITapGestureRecognizer *stgr2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    stgr2.numberOfTapsRequired = 1;
    [_introMyNicknameSendLabel addGestureRecognizer:stgr2];
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
        } else {
            
            PFObject *user = [PFUser currentUser];
            user[@"nickName"] = _introMyNicknameField.text;
            
            if (_selectSexController.selectedSegmentIndex == 0) {
                user[@"sex"] = @"male";
            } else {
                user[@"sex"] = @"female";
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
                
                [self registerApplyList];
                [hud hide:YES];
                if ([self.navigationController isViewLoaded]) {
                    [self.navigationController popToRootViewControllerAnimated:YES];
                } else {
                    [self dismissViewControllerAnimated:YES completion:nil];
                }
            }];
        }
    } else {
        [self.view endEditing:YES];
    }
}

- (void) registerApplyList
{
    // pinコード入力している場合(CoreDataにデータがある場合)、PartnerApplyListにレコードを入れる
    PartnerInvitedEntity *pie = [PartnerInvitedEntity MR_findFirst];
    if (pie.familyId) {
        // PartnerApplyListにレコードを突っ込む
        PFObject *object = [PFObject objectWithClassName:@"PartnerApplyList"];
        object[@"familyId"] = pie.familyId;
        object[@"applyingUserId"] = [PFUser currentUser][@"userId"];
        [object saveInBackground];
    }
}

@end
