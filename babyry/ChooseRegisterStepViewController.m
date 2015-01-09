//
//  ChooseRegisterStepViewController.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/09/11.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ChooseRegisterStepViewController.h"
#import "IdIssue.h"
#import "TmpUser.h"
#import "Logger.h"
#import "Account.h"
#import "PartnerInvitedEntity.h"
#import "Logger.h"
#import "CloseButtonView.h"
#import "ChildProperties.h"
#import "MBProgressHUD.h"

@interface ChooseRegisterStepViewController ()

@end

@implementation ChooseRegisterStepViewController

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
    
    [self makeDismisButton];
    
    UITapGestureRecognizer *openSignUpView = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(openSignUpView)];
    openSignUpView.numberOfTapsRequired = 1;
    [_registerButton addGestureRecognizer:openSignUpView];
    
    UITapGestureRecognizer *continueWithNoLogin = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(continueWithNoLogin)];
    continueWithNoLogin.numberOfTapsRequired = 1;
    [_noRegisterButton addGestureRecognizer:continueWithNoLogin];
    
    UITapGestureRecognizer *facebookLogin = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(facebookLogin)];
    facebookLogin.numberOfTapsRequired = 1;
    [_facebookLoginButton addGestureRecognizer:facebookLogin];
    
    _isSignUpCompleted = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    if (_isSignUpCompleted == YES) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)makeDismisButton
{
    CloseButtonView *view = [CloseButtonView view];
    CGRect rect = view.frame;
    rect.origin.x = 10;
    rect.origin.y = 30;
    view.frame = rect;
    
    UITapGestureRecognizer *logoutGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(dismisViewController)];
    logoutGesture.numberOfTapsRequired = 1;
    [view addGestureRecognizer:logoutGesture];
    
    [self.view addSubview:view];
}

- (void)dismisViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)openSignUpView
{
    // Customize the Sign Up View Controller
    MySignUpViewController *signUpViewController = [[MySignUpViewController alloc] init];
    signUpViewController.delegate = self;
    signUpViewController.fields = PFSignUpFieldsUsernameAndPassword |
    PFSignUpFieldsAdditional |
    PFSignUpFieldsDismissButton |
    PFSignUpFieldsSignUpButton;

    // Present Log In View Controller
    [self presentViewController:signUpViewController animated:YES completion:NULL];
}

///////////////////////////////////////////////////////
// PFSignUpViewControllerのmethodたち
// Sent to the delegate to determine whether the sign up request should be submitted to the server.
// 以下のメソッドはLogin系と同じ
- (BOOL)signUpViewController:(PFSignUpViewController *)signUpController shouldBeginSignUp:(NSDictionary *)info {
    BOOL informationComplete = YES;
    NSString *errorMessage = @"";
    
    // 埋まってないfieldチェック
    for (id key in info) {
        NSString *field = [info objectForKey:key];
        if (!field || field.length == 0) { // check completion
            errorMessage = @"入力が完了していない項目があります";
            break;
        }
    }
    
    errorMessage = [Account checkEmailRegisterFields:[info objectForKey:@"username"] password:[info objectForKey:@"password"] passwordConfirm:[info objectForKey:@"additional"]];
    
    if ([errorMessage isEqualToString:@""]){
        errorMessage = [Account checkDuplicateEmail:[info objectForKey:@"username"]];
    }
    
    // Display an alert if a field wasn't completed
    if (![errorMessage isEqualToString:@""]) {
        informationComplete = NO;
        [[[UIAlertView alloc] initWithTitle:@""
                                    message:errorMessage
                                   delegate:nil
                          cancelButtonTitle:@"ok"
                          otherButtonTitles:nil] show];
    }
    
    return informationComplete;
}

// Sent to the delegate when a PFUser is signed up.
- (void)signUpViewController:(PFSignUpViewController *)signUpController didSignUpUser:(PFUser *)user {
    [user refresh];
    // 確認用パスワードは平文で格納されちゃうので消す
    user[@"additional"] = @"";
    
    user[@"email"] = user[@"username"];
    
    // user_idを発行して保存
    user[@"userId"] = [[[IdIssue alloc]init]issue:@"user"];
    
    // emailCommonに格納
    user[@"emailCommon"] = user[@"username"];
    
    [user save];
    [user refresh];
    
    // 本登録完了なのでCoreDataのisRegisteredをtureにする
    [TmpUser registerComplete];
    
    // Email Verify
    [Account sendVerifyEmail:user[@"emailCommon"]];
    
    // 子供のデータがCoreDataにあれば全て消す
    [ChildProperties removeChildPropertiesFromCoreData];
    
    _isSignUpCompleted = YES;
    [self dismissViewControllerAnimated:YES completion:NULL]; // Dismiss the PFSignUpViewController
}

// Sent to the delegate when the sign up attempt fails.
- (void)signUpViewController:(PFSignUpViewController *)signUpController didFailToSignUpWithError:(NSError *)error {
    [[[UIAlertView alloc] initWithTitle:@"登録エラー"
                                message:@"エラーが発生しました。メールアドレスとパスワードを確認後、もう一度お試しください。"
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

// Sent to the delegate when the sign up screen is dismissed.
- (void)signUpViewControllerDidCancelSignUp:(PFSignUpViewController *)signUpController {
    //NSLog(@"User dismissed the signUpViewController");
}

- (void)continueWithNoLogin
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"簡単会員ログイン中";
    
    IdIssue *idIssue = [[IdIssue alloc] init];
    PFUser *user = [PFUser user];
    user.username = [idIssue randomStringWithLength:8];
    user.password = [idIssue randomStringWithLength:8];
    user[@"userId"] = [idIssue issue:@"user"];
    
    // emailCommonは検索で使わなくなるから、本来は入れなくていいのだけど旧バージョンでは必要なのでuserIdを入れておく(申請までにはこのフローはなくなる)
    user[@"emailCommon"] = user.username;
    
    [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        [hud hide:YES];
        if (!error) {
            [TmpUser setTmpUserToCoreData:user.username password:(NSString *)user.password];
            [self dismissViewControllerAnimated:YES completion:nil];
        } else {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in continueWithNoLogin : %@", error]];
        }
    }];
}

- (void)facebookLogin
{
    NSArray *permissionsArray = [NSArray arrayWithObjects:@"public_profile", @"email", @"user_friends", nil];

    [PFFacebookUtils logInWithPermissions:permissionsArray block:^(PFUser *user, NSError *error) {
        if (!user) {
            if (error) {
                [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in facebookLogin : %@", error]];
            }
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"エラーが発生しました"
                                                            message:@"Facebookアカウントでの会員登録に失敗しました。\n再度お試し頂くか、メールアドレスでの登録をお願いします。"
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"OK", nil];
            [alert show];
        } else {
            if (!user.isNew) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"登録済みのアカウントです"
                                                                message:@"既に登録済みのアカウントです。\n新規登録はせずログインします。"
                                                               delegate:nil
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"OK", nil];
                [alert show];
                [TmpUser registerComplete];
                [self dismissViewControllerAnimated:YES completion:NULL];
                return;
            }

            // ここは、IntroPageRootViewControllerからのコピペ
            // PFLogInViewControllerDelegateのメソッドなのでとりあえずコピペで
            if (user[@"userId"] == nil) {
                user[@"userId"] = [[[IdIssue alloc]init]issue:@"user"];
                [user save];
            }
            
            if (user[@"email"] && ![user[@"email"] isEqualToString:@""]) {
                [self dismissViewControllerAnimated:YES completion:NULL];
                return;
            }
            
            if (user[@"emailCommon"] && ![user[@"emailCommon"] isEqualToString:@""]) {
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
                                return;
                            }
                            [TmpUser registerComplete];
                        }];
                    }
                }];
            }];
            [self dismissViewControllerAnimated:YES completion:NULL];
        }
    }];
}

@end
