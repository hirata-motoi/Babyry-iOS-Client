//
//  IntroPageRootViewController.m
//  babyry
//
//  Created by hirata.motoi on 2014/08/17.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "IntroPageRootViewController.h"
#import "UIColor+Hex.h"
#import "ChooseRegisterStepViewController.h"
#import "MyLogInViewController.h"
#import "IdIssue.h"
#import "Logger.h"
#import "TmpUser.h"
#import "InputPinCodeViewController.h"
#import "PartnerInvitedEntity.h"
#import "ChildProperties.h"

@interface IntroPageRootViewController ()

@end

@implementation IntroPageRootViewController
@synthesize delegate;

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
    
    self.view.backgroundColor = [UIColor_Hex colorWithHexString:@"000000" alpha:0.6];

    if (_invitedButton) {
        _invitedButton.layer.cornerRadius = 3;
        UITapGestureRecognizer *showInputPincodeView = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(showInputPincodeView)];
        showInputPincodeView.numberOfTapsRequired = 1;
        [_invitedButton addGestureRecognizer:showInputPincodeView];
    }
    if (_registerButton) {
        _registerButton.layer.cornerRadius = 3;
        UITapGestureRecognizer *showRegisterStepCheckView = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(showRegisterStepCheckView)];
        showRegisterStepCheckView.numberOfTapsRequired = 1;
        [_registerButton addGestureRecognizer:showRegisterStepCheckView];
    }
    if (_loginButton) {
        _loginButton.layer.cornerRadius = 3;
        UITapGestureRecognizer *openLoginView = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(openLoginView)];
        openLoginView.numberOfTapsRequired = 1;
        [_loginButton addGestureRecognizer:openLoginView];
    }
    [self setupSkipAction];
    
    // ひとまずこんな感じで
    UIColor *cornerColor = [UIColor_Hex colorWithHexString:@"858585" alpha:1.0];
    _skipFromFirst.layer.cornerRadius = 6;
    _skipFromFirst.layer.borderColor = cornerColor.CGColor;
    _skipFromFirst.layer.borderWidth = 2;
    _skipFromSecond.layer.cornerRadius = 6;
    _skipFromSecond.layer.borderColor = cornerColor.CGColor;
    _skipFromSecond.layer.borderWidth = 2;
    _skipFromThird.layer.cornerRadius = 6;
    _skipFromThird.layer.borderColor = cornerColor.CGColor;
    _skipFromThird.layer.borderWidth = 2;
    _skipFromFourth.layer.cornerRadius = 6;
    _skipFromFourth.layer.borderColor = cornerColor.CGColor;
    _skipFromFourth.layer.borderWidth = 2;
    _skipFromFifth.layer.cornerRadius = 6;
    _skipFromFifth.layer.borderColor = cornerColor.CGColor;
    _skipFromFifth.layer.borderWidth = 2;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // CoreDataに打った認証コードのデータが入っていたら会員登録に飛ばす
    // ただし、すでに会員登録済みの場合には飛ばさない
    PartnerInvitedEntity *pie = [PartnerInvitedEntity MR_findFirst];
    if (pie && ![PFUser currentUser]) {
        ChooseRegisterStepViewController *chooseRegisterStepViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ChooseRegisterStepViewController"];
        [self presentViewController:chooseRegisterStepViewController animated:YES completion:nil];
    }
}

- (void)setupSkipAction
{
    UILabel *target;
    if (_skipFromFirst) {
        target = _skipFromFirst;
    } else if (_skipFromSecond) {
        target = _skipFromSecond;
    } else if (_skipFromThird) {
        target = _skipFromThird;
    } else if (_skipFromFourth) {
        target = _skipFromFourth;
    } else {
        target = _skipFromFifth;
    }
    [self setupSkipGesture:target];
}

- (void)setupSkipGesture:(UILabel *)label
{
    UITapGestureRecognizer *skipGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(skip)];
    skipGesture.numberOfTapsRequired = 1;
    label.userInteractionEnabled = YES;
    [label addGestureRecognizer:skipGesture];
}

- (void)skip
{
    [self.delegate skipToLast:_currentIndex];
}

//- (void)openLoginView
//{
//    [self.delegate openLoginView];
//}

- (void)openLoginView
{
    // Customize the Log In View Controller
    MyLogInViewController *logInViewController = [[MyLogInViewController alloc] init];
    logInViewController.delegate = self;
    logInViewController.facebookPermissions = [NSArray arrayWithObjects:@"public_profile", @"email", @"user_friends", nil];
    logInViewController.fields =
    PFLogInFieldsUsernameAndPassword |
    PFLogInFieldsLogInButton |
    PFLogInFieldsPasswordForgotten |
    PFLogInFieldsFacebook |
    PFLogInFieldsDismissButton;
    
    logInViewController.introPageRootViewController = self;
    
    // Present Log In View Controller
    [self presentViewController:logInViewController animated:YES completion:NULL];
}

///////////////////////////////////////////////////////
// PFLogInViewControllerのmethodたち
// Sent to the delegate to determine whether the log in request should be submitted to the server.
// クライアントでvalidateを入れる。むだにParseと通信しない(お金発生しない)
- (BOOL)logInViewController:(PFLogInViewController *)logInController shouldBeginLogInWithUsername:(NSString *)username password:(NSString *)password {
    // Check if both fields are completed
    if (username && password && username.length != 0 && password.length != 0) {
        return YES; // Begin login process
    }
    
    [[[UIAlertView alloc] initWithTitle:@"入力されていない項目があります"
                                message:@"全ての項目を埋めてください"
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
    return NO; // Interrupt login process
}

// Sent to the delegate when a PFUser is logged in.
// ログイン後の処理
- (void)logInViewController:(PFLogInViewController *)logInController didLogInUser:(PFUser *)user {
    // facebook, twitterでの登録時にはuserIdが発行されないのでココで発行する
    
    if (user[@"userId"] == nil) {
        user[@"userId"] = [[[IdIssue alloc]init]issue:@"user"];
        [user save];
    }
    
    if (!user[@"emailCommon"]) {
        // emailがない場合はfacebookログイン
        if (user[@"email"] && ![user[@"email"] isEqualToString:@""]) {
            [self dismissViewControllerAnimated:YES completion:NULL];
            return;
        }
        
        [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (error) {
                [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in get facebook email : %@", error]];
                return;
            }
            if (![result objectForKey:@"email"]) {
                [Logger writeOneShot:@"crit" message:@"There is no email in facebook"];
                return;
            }
            
            // email重複チェック
            PFQuery *emailQuery = [PFQuery queryWithClassName:@"_User"];
            [emailQuery whereKey:@"emailCommon" equalTo:[result objectForKey:@"email"]];
            [emailQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
                if (error) {
                    [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in check duplicate email. Email:%@ Error:%@", result[@"email"], error]];
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"メールアドレスの保存に\n失敗しました"
                                                                    message:@"電波状況のよい場所で再度お試しください。"
                                                                   delegate:nil
                                                          cancelButtonTitle:nil
                                                          otherButtonTitles:@"OK", nil
                                          ];
                    [alert show];
                    [PFUser logOut];
                    [self dismissViewControllerAnimated:YES completion:nil];
                    return;
                }
                
                if([objects count] > 0) {
                    [Logger writeOneShot:@"warn" message:[NSString stringWithFormat:@"Warn in Email Duplicate Check. Duplicate Count:%d, Email:%@", objects.count, result[@"email"]]];
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"メールアドレスの保存に\n失敗しました"
                                                                    message:@"このfacebookアカウントで使用しているメールアドレスは既に登録済みです。"
                                                                   delegate:nil
                                                          cancelButtonTitle:nil
                                                          otherButtonTitles:@"OK", nil
                                          ];
                    [alert show];
                    [PFUser logOut];
                    [self dismissViewControllerAnimated:YES completion:nil];
                } else {
                    user[@"emailCommon"] = [result objectForKey:@"email"];
                    [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
                        if (error) {
                            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in save email saving : %@", error]];
                            
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"メールアドレスの保存に\n失敗しました"
                                                                            message:@"ネットワークエラーの可能性がありますので、しばらくしてからお試しください。"
                                                                           delegate:nil
                                                                  cancelButtonTitle:nil
                                                                  otherButtonTitles:@"OK", nil
                                                  ];
                            [alert show];
                            [PFUser logOut];
                        }
                        [TmpUser registerComplete];
                    }];
                }
            }];
        }];
    } else {
        [TmpUser registerComplete];
    }
    
    // 子供のデータがCoreDataにあれば全て消す
    [ChildProperties removeChildPropertiesFromCoreData];
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

// Sent to the delegate when the log in attempt fails.
// ログインが失敗したら
- (void)logInViewController:(PFLogInViewController *)logInController didFailToLogInWithError:(NSError *)error {
    [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Failed to login Error:%@", error]];
    [[[UIAlertView alloc] initWithTitle:@"ログインエラー"
                                message:@"ログインエラーが発生しました。メールアドレスとパスワードを確認してください。"
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

// Sent to the delegate when the log in screen is dismissed.
// ログインviewのばつが押されたら
- (void)logInViewControllerDidCancelLogIn:(PFLogInViewController *)logInController {
    [self.navigationController popViewControllerAnimated:YES];
}
///////////////////////////////////////////////

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)showRegisterStepCheckView
{
    ChooseRegisterStepViewController *chooseRegisterStepViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ChooseRegisterStepViewController"];
    chooseRegisterStepViewController.introPageRootViewController = self;
    [self presentViewController:chooseRegisterStepViewController animated:YES completion:nil];
}

- (void)showInputPincodeView
{
    InputPinCodeViewController *inputPinCodeViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"InputPinCodeViewController"];
    [self presentViewController:inputPinCodeViewController animated:YES completion:nil];
}


@end
