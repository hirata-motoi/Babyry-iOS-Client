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
    _dismisButton.layer.cornerRadius = _dismisButton.frame.size.width/2;
    UITapGestureRecognizer *dismisViewController = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(dismisViewController)];
    dismisViewController.numberOfTapsRequired = 1;
    [_dismisButton addGestureRecognizer:dismisViewController];
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
    
    // エラーメッセージが無い = 全部埋まっている場合はそれぞれの中身をチェック
    if ([errorMessage isEqualToString:@""]) {
        if (![self validateEmailWithString:[info objectForKey:@"username"]]) {
            errorMessage = @"メールアドレスを正しく入力してください";
        } else if(![[info objectForKey:@"password"] canBeConvertedToEncoding:NSASCIIStringEncoding]) {
            errorMessage = @"パスワードに全角文字は使用できません";
        } else if ([[info objectForKey:@"password"] length] < 8) {
            errorMessage = @"パスワードは8文字以上を設定してください";
        } else if (![[info objectForKey:@"password"] isEqualToString:[info objectForKey:@"additional"]]){
            errorMessage = @"確認用パスワードが一致しません";
        } else {
            PFQuery *emailQuery = [PFQuery queryWithClassName:@"_User"];
            [emailQuery whereKey:@"emailCommon" equalTo:[info objectForKey:@"username"]];
            PFObject *object = [emailQuery getFirstObject];
            if(object) {
                errorMessage = @"既に登録済みのメールアドレスです";
            }
        }
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
    
    _isSignUpCompleted = YES;
    [self dismissViewControllerAnimated:YES completion:NULL]; // Dismiss the PFSignUpViewController
}

// Sent to the delegate when the sign up attempt fails.
- (void)signUpViewController:(PFSignUpViewController *)signUpController didFailToSignUpWithError:(NSError *)error {
    //NSLog(@"Failed to sign up... %@", error);
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

- (BOOL)validateEmailWithString:(NSString*)email
{
    NSString *emailRegex = @"[\\S]+@[A-Za-z0-9.-]+\\.[A-Za-z]{1,10}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:email];
}

- (void)continueWithNoLogin
{
    IdIssue *idIssue = [[IdIssue alloc] init];
    PFUser *user = [PFUser user];
    user.username = [idIssue randomStringWithLength:8];
    user.password = [idIssue randomStringWithLength:8];
    user[@"userId"] = [idIssue issue:@"user"];
    
    // emailCommonは検索で使わなくなるから、本来は入れなくていいのだけど旧バージョンでは必要なのでuserIdを入れておく(申請までにはこのフローはなくなる)
    user[@"emailCommon"] = user.username;
    
    [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            [TmpUser setTmpUserToCoreData:user.username password:(NSString *)user.password];
            [self dismissViewControllerAnimated:YES completion:nil];
        } else {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in continueWithNoLogin : %@", error]];
        }
    }];
}

@end
