//
//  UserRegisterViewController.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/09/15.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "UserRegisterViewController.h"
#import "Navigation.h"
#import "Account.h"
#import "TmpUser.h"
#import <Parse/Parse.h>
#import <ParseFacebookUtils/PFFacebookUtils.h>
#import "Logger.h"
#import "MBProgressHUD.h"

@interface UserRegisterViewController ()

@end

@implementation UserRegisterViewController

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
    
    [Navigation setTitle:self.navigationItem withTitle:@"本登録を完了する" withSubtitle:nil withFont:nil withFontSize:0 withColor:nil];
    
    _defaultCommentViewRect = _mailAddressRegisterViewContainer.frame;
    
    UITapGestureRecognizer *registerByEmail = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(registerByEmail)];
    registerByEmail.numberOfTapsRequired = 1;
    [_mailAddressRegisterButton addGestureRecognizer:registerByEmail];
    
    UITapGestureRecognizer *registerByFacebook = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(registerByFacebook)];
    registerByFacebook.numberOfTapsRequired = 1;
    [_facebookRegisterButton addGestureRecognizer:registerByFacebook];
    
    UITapGestureRecognizer *hideKeyboard = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    hideKeyboard.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:hideKeyboard];
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

- (void)registerByEmail
{
    NSString *errorMessage = [Account checkEmailRegisterFields:_mailAddressField.text password:_passwordField.text passwordConfirm:_passwordComfirmField.text];
    
    // Display an alert if a field wasn't completed
    if (![errorMessage isEqualToString:@""]) {
        [[[UIAlertView alloc] initWithTitle:@""
                                    message:errorMessage
                                   delegate:nil
                          cancelButtonTitle:@"ok"
                          otherButtonTitles:nil] show];
        return;
    }
    
    PFUser *user = [PFUser currentUser];
    user.username = _mailAddressField.text;
    user.password = _passwordField.text;
    user[@"emailCommon"] = _mailAddressField.text;
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"データ保存";
    [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
        if (error){
            [hud hide:YES];
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in registerByEmail : %@", error]];
            [[[UIAlertView alloc] initWithTitle:@"データの保存に失敗しました"
                                        message:@"ネットワークエラーが発生しました。もう一度お試しください。"
                                       delegate:nil
                              cancelButtonTitle:@"ok"
                              otherButtonTitles:nil] show];
            return;
        }
        
        [hud hide:YES];
        [TmpUser registerComplete];
        [[[UIAlertView alloc] initWithTitle:@"登録が完了しました"
                                    message:@"入力されたメールアドレスに確認メールをお送りしましたので、本文に記載されているURLをクリックしてメールアドレスを有効化してください。"
                                   delegate:nil
                          cancelButtonTitle:@"ok"
                          otherButtonTitles:nil] show];
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

- (void)registerByFacebook
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"Facebookログイン中";
    PFUser *user = [PFUser currentUser];
    if (![PFFacebookUtils isLinkedWithUser:user]) {
        [PFFacebookUtils linkUser:user permissions:[NSArray arrayWithObjects:@"public_profile", @"email", @"user_friends", nil] block:^(BOOL succeeded, NSError *error) {
            if (error) {
                // ひも付けエラーならそのまま画面は移動せずにアラートだけ出す
                [hud hide:YES];
                [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in registerByFacebook : %@", error]];
                [[[UIAlertView alloc] initWithTitle:@"Facebookログインに失敗しました"
                                            message:nil
                                           delegate:nil
                                  cancelButtonTitle:@"ok"
                                  otherButtonTitles:nil] show];
                return;
            }
            
            // ここは大体がIntroPageRootViewControllerのコピペ
            // Classにまとめたかったが、ここでエラーが起きた場合には、ログアウトではなくfacebookアカウントとunlinkする処理になるため、いまはコピペで。
            [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                if (error) {
                    // メアド取得失敗したのでunlinkする
                    [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in get facebook email at registerByFacebook : %@", error]];
                    [self unlinkFacebookAccount:user];
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ネットワークエラー"
                                                                    message:@"電波状況のよい場所で再度お試しください。"
                                                                   delegate:nil
                                                          cancelButtonTitle:nil
                                                          otherButtonTitles:@"OK", nil
                                          ];
                    [alert show];
                    return;
                }
                if (![result objectForKey:@"email"]) {
                    // メアドが入っていないのでunlinkする
                    [Logger writeOneShot:@"crit" message:@"There is no email in facebook at registerByFacebook"];
                    [self unlinkFacebookAccount:user];
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Facebook接続エラー"
                                                                    message:@"Facebookのアカウントからメールアドレスが取得できませんでした。"
                                                                   delegate:nil
                                                          cancelButtonTitle:nil
                                                          otherButtonTitles:@"OK", nil
                                          ];
                    [alert show];
                    return;
                }
                
                // email重複チェック
                PFQuery *emailQuery = [PFQuery queryWithClassName:@"_User"];
                [emailQuery whereKey:@"emailCommon" equalTo:[result objectForKey:@"email"]];
                [emailQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
                    if (error) {
                        // クエリのエラーの場合unlinkする
                        [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in check duplicate email. Email:%@ Error:%@", result[@"email"], error]];
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"メールアドレスの保存に\n失敗しました"
                                                                        message:@"電波状況のよい場所で再度お試しください。"
                                                                       delegate:nil
                                                              cancelButtonTitle:nil
                                                              otherButtonTitles:@"OK", nil
                                              ];
                        [alert show];
                        [self unlinkFacebookAccount:user];
                        return;
                    }
                    
                    if([objects count] > 0) {
                        // 重複チェックエラー、unlink
                        [Logger writeOneShot:@"warn" message:[NSString stringWithFormat:@"Warn in Email Duplicate Check. Duplicate Count:%d, Email:%@", objects.count, result[@"email"]]];
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"メールアドレスの保存に\n失敗しました"
                                                                        message:@"このfacebookアカウントで使用しているメールアドレスは既に登録済みです。"
                                                                       delegate:nil
                                                              cancelButtonTitle:nil
                                                              otherButtonTitles:@"OK", nil
                                              ];
                        [alert show];
                        [self unlinkFacebookAccount:user];
                    } else {
                        user[@"emailCommon"] = [result objectForKey:@"email"];
                        user[@"username"] = [result objectForKey:@"email"];
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
                                [self unlinkFacebookAccount:user];
                            }
                            // すべてが成功した場合だけ、isRegisteredをtrueにする
                            [TmpUser registerComplete];
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"完了"
                                                                            message:@"簡易ログイン会員とFacebookアカウントをひも付けが完了しました。"
                                                                           delegate:nil
                                                                  cancelButtonTitle:nil
                                                                  otherButtonTitles:@"OK", nil
                                                  ];
                            [alert show];
                            [self.navigationController popViewControllerAnimated:YES];
                        }];
                    }
                }];
            }];
        }];
    }
}

- (void)hideKeyboard
{
    [self.view endEditing:YES];
}

- (void)keyboardWillShow:(NSNotification*)notification
{
    // Get userInfo
    NSDictionary *userInfo;
    userInfo = [notification userInfo];
    
    // Calc overlap of keyboardFrame and textViewFrame
    CGRect keyboardFrame;
    CGRect textViewFrame;
    keyboardFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardFrame = [_mailAddressRegisterViewContainer.superview convertRect:keyboardFrame fromView:nil];
    textViewFrame = _mailAddressRegisterViewContainer.frame;
    float overlap;
    overlap = MAX(0.0f, CGRectGetMaxY(textViewFrame) - CGRectGetMinY(keyboardFrame));
    
    NSTimeInterval duration;
    UIViewAnimationCurve animationCurve;
    void (^animations)(void);
    duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    animations = ^(void) {
        CGRect viewFrame = _mailAddressRegisterViewContainer.frame;
        viewFrame.origin.y -= overlap;
        _mailAddressRegisterViewContainer.frame = viewFrame;
    };
    [UIView animateWithDuration:duration delay:0.0 options:(animationCurve << 16) animations:animations completion:nil];
}

- (void)keybaordWillHide:(NSNotification*)notification
{
    // Get userInfo
    NSDictionary *userInfo;
    userInfo = [notification userInfo];
    
    CGRect textViewFrame;
    textViewFrame = _mailAddressRegisterViewContainer.frame;
    
    NSTimeInterval duration;
    UIViewAnimationCurve animationCurve;
    void (^animations)(void);
    duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    animations = ^(void) {
        CGRect viewFrame = _mailAddressRegisterViewContainer.frame;
        viewFrame.origin.y =  _defaultCommentViewRect.origin.y;
        _mailAddressRegisterViewContainer.frame = viewFrame;
    };
    [UIView animateWithDuration:duration delay:0.0 options:(animationCurve << 16) animations:animations completion:nil];
}

- (void) unlinkFacebookAccount:(PFUser *)user
{
    [PFFacebookUtils unlinkUserInBackground:user block:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"unlink facebook account"]];
        }
        // エラーの場合どうしたものか。。。
        if (error) {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Faild in unlink facebook account : %@", error]];
        }
    }];
}

@end
