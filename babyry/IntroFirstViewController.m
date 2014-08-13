//
//  IntroFirstViewController.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/07/08.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "IntroFirstViewController.h"
#import "UIViewController+MJPopupViewController.h"
#import "FamilyApplyViewController.h"
#import "FamilyApplyListViewController.h"
#import "IdIssue.h"

@interface IntroFirstViewController ()

@end

@implementation IntroFirstViewController

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
    
//    _applyCheckingFlag = 0;
    
    _introPageIndex = 0;
    // PageViewController追加
    _pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    _pageViewController.dataSource = self;
    
    CGRect frame = _pageViewController.view.frame;
    frame.size.height = self.view.frame.size.height - 70; // 70は magic number!
    _pageViewController.view.frame = frame;
    
    NSLog(@"0ページ目を表示");
    UIViewController *startingViewController = [self viewControllerAtIndex:0];
    NSArray *viewControllers = @[startingViewController];
    [_pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    [self addChildViewController:_pageViewController];
    [self.view addSubview:_pageViewController.view];
    [_pageViewController didMoveToParentViewController:self];
    
//    // Add Listener
//    _inviteLabel.tag = 1;
//    UITapGestureRecognizer *singleTapGestureRecognizer1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
//    singleTapGestureRecognizer1.numberOfTapsRequired = 1;
//    [_inviteLabel addGestureRecognizer:singleTapGestureRecognizer1];
//    
//    
//    _invitedLabel.tag = 2;
//    UITapGestureRecognizer *singleTapGestureRecognizer2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
//    singleTapGestureRecognizer2.numberOfTapsRequired = 1;
//    [_invitedLabel addGestureRecognizer:singleTapGestureRecognizer2];
//    
//    _logout.layer.cornerRadius = _logout.frame.size.width/2;
//    _logout.tag = 99;
//    UITapGestureRecognizer *singleTapGestureRecognizer99 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
//    singleTapGestureRecognizer99.numberOfTapsRequired = 1;
//    [_logout addGestureRecognizer:singleTapGestureRecognizer99];
    
    // add gesture on self.view
//    UITapGestureRecognizer *singleTapGestureRecognizer0 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
//    singleTapGestureRecognizer0.numberOfTapsRequired = 1;
//    [self.view addGestureRecognizer:singleTapGestureRecognizer0];
//    [self.navigationController setNavigationBarHidden:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    NSLog(@"viewDidAppear in IntroFirstViewController");
    [super viewDidAppear:animated];
    
    if ([PFUser currentUser]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
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

///////////////////////////////////////
// pageViewController用のメソッド
// provides the view controller after the current view controller. In other words, we tell the app what to display for the next screen.
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSInteger index = viewController.view.tag;
    NSLog(@"viewControllerBeforeViewController %d", index);
    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }
    
    index--;
    NSLog(@"index-- :%d", index);
    return [self viewControllerAtIndex:index];
}

// provides the view controller before the current view controller. In other words, we tell the app what to display when user switches back to the previous screen.
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSInteger index = viewController.view.tag;
    NSLog(@"viewControllerAfterViewController %d", index);
    
    if (index >= 4 || index == NSNotFound) {
        return nil;
    }
    
    index++;
    NSLog(@"index++ :%d", index);
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)viewControllerAtIndex:(NSUInteger)index
{
    NSLog(@"viewControllerAtIndex");
    UIViewController *introViewController = [[UIViewController alloc] init];
    introViewController.view.backgroundColor = [UIColor colorWithRed:0.95 green:0.85 blue:0.85 alpha:1.0];
    if (index == 0) {
        UIViewController *firstVC = [self.storyboard instantiateViewControllerWithIdentifier:@"IntroPageFirstViewController"];
        [introViewController.view addSubview:firstVC.view];
    } else if (index == 1) {
        UIViewController *secondVC = [self.storyboard instantiateViewControllerWithIdentifier:@"IntroPageSecondViewController"];
        [introViewController.view addSubview:secondVC.view];
    } else if (index == 2) {
        UIViewController *thirdVC = [self.storyboard instantiateViewControllerWithIdentifier:@"IntroPageThirdViewController"];
        [introViewController.view addSubview:thirdVC.view];
    } else if (index == 3) {
        UIViewController *fourthVC = [self.storyboard instantiateViewControllerWithIdentifier:@"IntroPageFourthViewController"];
        [introViewController.view addSubview:fourthVC.view];
    } else if (index == 4) {
        UIViewController *fifthVC = [self.storyboard instantiateViewControllerWithIdentifier:@"IntroPageFifthViewController"];
        [introViewController.view addSubview:fifthVC.view];
    }
    introViewController.view.tag = index;
    NSLog(@"index %d is created.", index);
    
    return introViewController;
}

// 全体で何ページあるか返す Delegate Method コメント外すとPageControlがあらわれる

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return 5;
}
 
- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    return 0;
}
///////////////////////////////////////

- (IBAction)registerAction:(id)sender {
    [self openLoginView];
}

- (void)openLoginView
{
    // Create the log in view controller
    PFLogInViewController *logInViewController = [[PFLogInViewController alloc] init];
    [logInViewController setDelegate:self]; // Set ourselves as the delegate
    [logInViewController setFacebookPermissions:[NSArray arrayWithObjects:@"public_profile", @"email", nil]];
    [logInViewController setFields:
     PFLogInFieldsFacebook |
     PFLogInFieldsUsernameAndPassword |
     PFLogInFieldsPasswordForgotten |
     PFLogInFieldsLogInButton |
     PFLogInFieldsSignUpButton |
     PFLogInFieldsDismissButton
     ];
    
    
    logInViewController.logInView.usernameField.placeholder = @"メールアドレス";
    logInViewController.logInView.usernameField.keyboardType = UIKeyboardTypeASCIICapable;
    logInViewController.logInView.passwordField.placeholder = @"パスワード";
    logInViewController.logInView.passwordField.keyboardType = UIKeyboardTypeASCIICapable;
    
    
    //UIView *fieldsBackground2 = [[logInViewController.logInView subviews] objectAtIndex:0];
    // for example move down
    //[fieldsBackground2 setFrame:CGRectOffset(fieldsBackground2.frame,0,80.0f)];
    
    //[logInViewController.logInView setBackgroundColor:[UIColor whiteColor]];
    [logInViewController.logInView setLogo:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@""]]];
    
    // これ反映されない！困る！！！
    [logInViewController.logInView.logInButton setTitle:@"ログイン" forState:UIControlStateNormal];
    [logInViewController.logInView.logInButton setTitle:@"ログイン" forState:UIControlStateHighlighted];
    //[logInViewController.logInView.usernameField setBackground:[UIImage imageNamed:@"LoginFieldBack"]];
    //[logInViewController.logInView.passwordField setBackground:[UIImage imageNamed:@"LoginFieldBack"]];
    
    //[logInViewController.logInView.facebookButton setImage:nil forState:UIControlStateNormal];
    //[logInViewController.logInView.facebookButton setImage:nil forState:UIControlStateHighlighted];
    //[logInViewController.logInView.facebookButton setBackgroundImage:[UIImage imageNamed:@"facebook_down.png"] forState:UIControlStateHighlighted];
    //[logInViewController.logInView.facebookButton setBackgroundImage:[UIImage imageNamed:@"facebook.png"] forState:UIControlStateNormal];
    //[logInViewController.logInView.facebookButton setTitle:@"ふぇいすぶっく" forState:UIControlStateNormal];
    //[logInViewController.logInView.facebookButton setTitle:@"ふぇいすぶっく" forState:UIControlStateHighlighted];
    
    //[logInViewController.logInView.twitterButton setImage:nil forState:UIControlStateNormal];
    //[logInViewController.logInView.twitterButton setImage:nil forState:UIControlStateHighlighted];
    //[logInViewController.logInView.twitterButton setBackgroundImage:[UIImage imageNamed:@"twitter.png"] forState:UIControlStateNormal];
    //[logInViewController.logInView.twitterButton setBackgroundImage:[UIImage imageNamed:@"twitter_down.png"] forState:UIControlStateHighlighted];
    //[logInViewController.logInView.twitterButton setTitle:@"ついったー" forState:UIControlStateNormal];
    //[logInViewController.logInView.twitterButton setTitle:@"ついったー" forState:UIControlStateHighlighted];
    
    //[logInViewController.logInView.signUpButton setBackgroundImage:[UIImage imageNamed:@"signup.png"] forState:UIControlStateNormal];
    //[logInViewController.logInView.signUpButton setBackgroundImage:[UIImage imageNamed:@"signup_down.png"] forState:UIControlStateHighlighted];
    [logInViewController.logInView.signUpButton setTitle:@"新規アカウント作成" forState:UIControlStateNormal];
    [logInViewController.logInView.signUpButton setTitle:@"新規アカウント作成" forState:UIControlStateHighlighted];
    
    [logInViewController.logInView.passwordForgottenButton setBackgroundImage:[UIImage imageNamed:@"ForgetPasswordLabel"] forState:UIControlStateNormal];
    
    // Add login field background
    UIImageView *fieldsBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LoginViewImage"]];
    fieldsBackground.frame = self.view.frame;
    [logInViewController.logInView insertSubview:fieldsBackground atIndex:0];
    
    // Remove text shadow
    CALayer *layer = logInViewController.logInView.usernameField.layer;
    layer.shadowOpacity = 0.0;
    layer = logInViewController.logInView.passwordField.layer;
    layer.shadowOpacity = 0.0;
    layer = logInViewController.logInView.externalLogInLabel.layer;
    layer.shadowOpacity = 0.0;
    

    
    // Set field text color
    //[logInViewController.logInView.usernameField setTextColor:[UIColor colorWithRed:135.0f/255.0f green:118.0f/255.0f blue:92.0f/255.0f alpha:1.0]];
    //[logInViewController.logInView.passwordField setTextColor:[UIColor colorWithRed:135.0f/255.0f green:118.0f/255.0f blue:92.0f/255.0f alpha:1.0]];
    
    
    logInViewController.logInView.externalLogInLabel.text = @"ソーシャルアカウントでログイン";
    logInViewController.logInView.signUpLabel.text = @"";
    
    // Create the sign up view controller
    PFSignUpViewController *signUpViewController = [self makeSignUpView];
    [signUpViewController setDelegate:self]; // Set ourselves as the delegate
    
    [signUpViewController.signUpView setLogo:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@""]]];
    UIImageView *fieldsBackground2 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LoginViewImage"]];
    fieldsBackground2.frame = self.view.frame;
    [signUpViewController.signUpView insertSubview:fieldsBackground2 atIndex:0];
    
    // Assign our sign up controller to be displayed from the login controller
    [logInViewController setSignUpController:signUpViewController];
    
    // Present the log in view controller
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
    NSLog(@"Login!!!");

    if (user[@"userId"] == nil) {
        user[@"userId"] = [[[IdIssue alloc]init]issue:@"user"];
        [user save];
    }
    
    if (!user[@"email"] || ![user[@"email"] isEqualToString:@""]) {
        [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error && [result objectForKey:@"email"]) {
                user[@"email"] = [result objectForKey:@"email"];
                [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
                    if (error) {
                        NSLog(@"error %@", error);
                        // メアドが保存できないのは、ネットワークのせいかduplicate entryのせい
                        // なのでアラートをだしてログアウトさせる
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"メールアドレスの保存に\n失敗しました"
                                                                        message:@"facebookで利用している\nメールアドレスで既にBabyryに\n登録している場合は\nfacebookアカウントでの\nログインは出来ません。\nそうでない場合は、\nネットワークエラーの可能性が\nありますので\nしばらくしてからお試しください。"
                                                                       delegate:nil
                                                              cancelButtonTitle:nil
                                                              otherButtonTitles:@"OK", nil
                                              ];
                        [alert show];
                        [PFUser logOut];
                        [self dismissViewControllerAnimated:YES completion:nil];
                    }
                }];
            } else {
                NSLog(@"%@", error);
            }
        }];
    }
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

// Sent to the delegate when the log in attempt fails.
// ログインが失敗したら
- (void)logInViewController:(PFLogInViewController *)logInController didFailToLogInWithError:(NSError *)error {
    //NSLog(@"Failed to log in...");
}

// Sent to the delegate when the log in screen is dismissed.
// ログインviewのばつが押されたら
- (void)logInViewControllerDidCancelLogIn:(PFLogInViewController *)logInController {
    [self.navigationController popViewControllerAnimated:YES];
}
///////////////////////////////////////////////


- (PFSignUpViewController *) makeSignUpView{
    // Create the sign up view controller
    PFSignUpViewController *signUpViewController = [[PFSignUpViewController alloc] init];
    [signUpViewController setDelegate:self]; // Set ourselves as the delegate
    [signUpViewController setFields:
     PFSignUpFieldsUsernameAndPassword |
     PFSignUpFieldsAdditional |
     PFLogInFieldsFacebook |
     PFLogInFieldsTwitter |
     PFSignUpFieldsDismissButton |
     PFSignUpFieldsSignUpButton
     ];

    signUpViewController.signUpView.usernameField.placeholder = @"メールアドレス";
    signUpViewController.signUpView.usernameField.keyboardType = UIKeyboardTypeASCIICapable;
    
    signUpViewController.signUpView.passwordField.placeholder = @"パスワード";
    signUpViewController.signUpView.passwordField.keyboardType = UIKeyboardTypeASCIICapable;
    
    signUpViewController.signUpView.additionalField.placeholder = @"パスワード(確認)";
    signUpViewController.signUpView.additionalField.keyboardType = UIKeyboardTypeASCIICapable;
    signUpViewController.signUpView.additionalField.secureTextEntry = YES;
    
    [signUpViewController.signUpView setLogo:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@""]]];
    UIImageView *fieldsBackground2 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LoginViewImage"]];
    fieldsBackground2.frame = self.view.frame;
    [signUpViewController.signUpView insertSubview:fieldsBackground2 atIndex:0];

    return signUpViewController;
}

///////////////////////////////////////////////////////
// PFSignUpViewControllerのmethodたち
// Sent to the delegate to determine whether the sign up request should be submitted to the server.
// 以下のメソッドはLogin系と同じ
- (BOOL)signUpViewController:(PFSignUpViewController *)signUpController shouldBeginSignUp:(NSDictionary *)info {
    BOOL informationComplete = YES;
    NSString *errorMessage = @"";
    
    NSString *password = [[NSString alloc] init];
    NSString *passwordConfirm = [[NSString alloc] init];
    
    for (id key in info) {
        NSString *field = [info objectForKey:key];
        if (!field || field.length == 0) { // check completion
            errorMessage = @"入力が完了していない項目があります";
            break;
        }
        if ([key isEqualToString:@"password"]){
            if(![field canBeConvertedToEncoding:NSASCIIStringEncoding]) {
                errorMessage = @"パスワードに全角文字は使用できません";
                break;
            } else if ([field length] < 8) {
                errorMessage = @"パスワードは8文字以上を設定してください";
                break;
            }
            password = field;
        } else if ([key isEqualToString:@"additional"]) {
            passwordConfirm = field;
        } else if ([key isEqualToString:@"username"]) {
            if (![self validateEmailWithString:field]) {
                errorMessage = @"メールアドレスを正しく入力してください";
                break;
            }
        }
    }
    
    if (![password isEqualToString:passwordConfirm]) {
        if ([errorMessage isEqualToString:@""]) {
            errorMessage = @"確認用パスワードが一致しません";
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
    // 確認用パスワードは平文で格納されちゃうので消す
    user[@"additional"] = @"";
    
    // authDataがなければ(Babyry専用ユーザーなら)
    if (!user[@"authData"]) {
        user[@"email"] = user[@"username"];
    }
    
    // user_idを発行して保存
    user[@"userId"] = [[[IdIssue alloc]init]issue:@"user"];
    [user save];
    
    [self dismissViewControllerAnimated:YES completion:NULL]; // Dismiss the PFSignUpViewController
}

// Sent to the delegate when the sign up attempt fails.
- (void)signUpViewController:(PFSignUpViewController *)signUpController didFailToSignUpWithError:(NSError *)error {
    //NSLog(@"Failed to sign up...");
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

@end
