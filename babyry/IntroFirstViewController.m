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
#import "IntroPageRootViewController.h"
#import "UIColor+Hex.h"
#import <QuartzCore/QuartzCore.h>
#import "ColorUtils.h"
#import "MyLogInViewController.h"
#import "MySignUpViewController.h"

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
    
    _introPageIndex = 0;
    // PageViewController追加
    _pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    _pageViewController.dataSource = self;
    
    UIViewController *startingViewController = [self viewControllerAtIndex:0];
    _currentPageControl = 0;
    NSArray *viewControllers = @[startingViewController];
    [_pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    [self addChildViewController:_pageViewController];
    [self.view addSubview:_pageViewController.view];
    [_pageViewController didMoveToParentViewController:self];
   
    // pageController
    NSArray *subviews = _pageViewController.view.subviews;
    UIPageControl *thisControl = nil;
    for (int i=0; i<[subviews count]; i++) {
        if ([[subviews objectAtIndex:i] isKindOfClass:[UIPageControl class]]) {
            thisControl = (UIPageControl *)[subviews objectAtIndex:i];
            thisControl.backgroundColor = [UIColor_Hex colorWithHexString:@"000000" alpha:0.6];
            thisControl.pageIndicatorTintColor = [UIColor grayColor];
            thisControl.currentPageIndicatorTintColor = [UIColor whiteColor];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
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
    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }
    
    index--;
    return [self viewControllerAtIndex:index];
}

// provides the view controller before the current view controller. In other words, we tell the app what to display when user switches back to the previous screen.
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSInteger index = viewController.view.tag;
    
    if (index >= 4 || index == NSNotFound) {
        return nil;
    }
    
    index++;
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)viewControllerAtIndex:(NSUInteger)index
{
    _currentPageControl = index;
    IntroPageRootViewController *vc;
    if (index == 0) {
        vc = [self.storyboard instantiateViewControllerWithIdentifier:@"IntroPageFirstViewController"];
    } else if (index == 1) {
        vc = [self.storyboard instantiateViewControllerWithIdentifier:@"IntroPageSecondViewController"];
    } else if (index == 2) {
        vc = [self.storyboard instantiateViewControllerWithIdentifier:@"IntroPageThirdViewController"];
    } else if (index == 3) {
        vc = [self.storyboard instantiateViewControllerWithIdentifier:@"IntroPageFourthViewController"];
    } else if (index == 4) {
        vc = [self.storyboard instantiateViewControllerWithIdentifier:@"IntroPageFifthViewController"];
    }
    vc.delegate = self;
    vc.currentIndex = index;
    vc.view.tag = index;
    
    return vc;
}

// 全体で何ページあるか返す Delegate Method コメント外すとPageControlがあらわれる

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return 5;
}
 
- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    return _currentPageControl;
}
///////////////////////////////////////
- (void)skipToLast:(NSInteger)currentIndex
{
    NSInteger waitIndex = 0;
    for (NSInteger i = currentIndex+1; i <= 4; i++) {
        CGFloat interval = 0.1 * waitIndex;
        NSNumber *n = [NSNumber numberWithInteger:i];
        NSMutableDictionary *info = [[NSMutableDictionary alloc]initWithObjects:@[n] forKeys:@[@"index"]];
        [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(nextPage:) userInfo:info repeats:NO];
        waitIndex++;
    }
}

- (void)nextPage:(NSTimer *)timer
{
    NSMutableDictionary *info = timer.userInfo;
    NSInteger index = [info[@"index"] integerValue];
    [_pageViewController setViewControllers:@[ [self viewControllerAtIndex:index] ] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
}

- (IBAction)registerAction:(id)sender {
    [self openLoginView];
}

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
    PFLogInFieldsSignUpButton |
    PFLogInFieldsDismissButton;
    
    // Customize the Sign Up View Controller
    MySignUpViewController *signUpViewController = [[MySignUpViewController alloc] init];
    signUpViewController.delegate = self;
    signUpViewController.fields = PFSignUpFieldsUsernameAndPassword |
    PFSignUpFieldsAdditional |
    PFSignUpFieldsDismissButton |
    PFSignUpFieldsSignUpButton;
    logInViewController.signUpController = signUpViewController;
    
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
        if (!user[@"email"] || [user[@"email"] isEqualToString:@""]) {
            [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                if (!error && [result objectForKey:@"email"]) {
                    
                    // email重複チェック
                    PFQuery *emailQuery = [PFQuery queryWithClassName:@"_User"];
                    [emailQuery whereKey:@"emailCommon" equalTo:[result objectForKey:@"email"]];
                    [emailQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error){
                        if(object) {
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
                                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"メールアドレスの保存に\n失敗しました"
                                                                                    message:@"ネットワークエラーの可能性がありますので、しばらくしてからお試しください。"
                                                                                   delegate:nil
                                                                          cancelButtonTitle:nil
                                                                          otherButtonTitles:@"OK", nil
                                                          ];
                                    [alert show];
                                    [PFUser logOut];
                                    [self dismissViewControllerAnimated:YES completion:nil];
                                }
                            }];
                        }
                    }];
                }
            }];
        }
    }
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

// Sent to the delegate when the log in attempt fails.
// ログインが失敗したら
- (void)logInViewController:(PFLogInViewController *)logInController didFailToLogInWithError:(NSError *)error {
    //NSLog(@"Failed to log in...");
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

///////////////////////////////////////////////////////
// PFSignUpViewControllerのmethodたち
// Sent to the delegate to determine whether the sign up request should be submitted to the server.
// 以下のメソッドはLogin系と同じ
- (BOOL)signUpViewController:(PFSignUpViewController *)signUpController shouldBeginSignUp:(NSDictionary *)info {
    BOOL informationComplete = YES;
    NSString *errorMessage = @"";
    
    NSString *email = [[NSString alloc] init];
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
            email = field;
        }
    }
    
    if (![password isEqualToString:passwordConfirm]) {
        if ([errorMessage isEqualToString:@""]) {
            errorMessage = @"確認用パスワードが一致しません";
        }
    }
    
    if (informationComplete) {
        // email重複チェック
        PFQuery *emailQuery = [PFQuery queryWithClassName:@"_User"];
        [emailQuery whereKey:@"emailCommon" equalTo:email];
        PFObject *object = [emailQuery getFirstObject];
        if(object) {
            errorMessage = @"既に登録済みのメールアドレスです";
            informationComplete = NO;
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

@end
