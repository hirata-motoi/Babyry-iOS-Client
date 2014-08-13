//
//  ViewController.m
//  babyrydev
//
//  Created by kenjiszk on 2014/05/30.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ViewController.h"
#import "ImageCache.h"
#import "GlobalSettingViewController.h"
#import "IdIssue.h"
#import "FamilyApplyViewController.h"
#import "FamilyRole.h"
#import "MaintenanceViewController.h"
#import "Config.h"
#import "IntroFirstViewController.h"
#import "PageContentViewController.h"
#import "IntroChildNameViewController.h"
#import "PushNotification.h"
#import "UIColor+Hex.h"
#import "AWSS3Utils.h"
#import "ImageEdit.h"
#import "TagAlbumOperationViewController.h"
#import "ArrayUtils.h"
#import "Navigation.h"
#import "Partner.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // よく使うからここに書いておく
    //[PFUser logOut];
    
    _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _hud.labelText = @"データ準備中";
    //_hud.margin = 0;
    //_hud.labelFont = [UIFont fontWithName:@"HelveticaNeue-Thin" size:15];
    
    _only_first_load = 1;
    
    // navigation controller
    CGRect rect = CGRectMake(0, 0, 130, 38);
    UIImageView *titleview = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"babyryTitleReverse"]];
    titleview.frame = rect;
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(176, 0, 130, 38)];
    [view addSubview:titleview];
    self.navigationItem.titleView = view;
    self.navigationController.navigationBar.barTintColor = [UIColor_Hex colorWithHexString:@"f4c510" alpha:1.0f];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc]
                                             initWithTitle:@""
                                             style:UIBarButtonItemStylePlain
                                             target:nil
                                             action:nil];
    
    // partner情報初期化
    [Partner initialize];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    _currentUser = [PFUser currentUser];
    if (!_currentUser) { // No user logged in
        _only_first_load = 1;
        [_pageViewController.view removeFromSuperview];
        [_pageViewController removeFromParentViewController];
        _pageViewController = nil;
        [self openLoginView];
    } else {
        // メンテナンス状態かどうか確認
        // バックグラウンドで行わないと一瞬固まる
        PFQuery *maintenanceQuery = [PFQuery queryWithClassName:@"Config"];
        maintenanceQuery.cachePolicy = kPFCachePolicyNetworkElseCache;
        [maintenanceQuery whereKey:@"key" equalTo:@"maintenance"];
        [maintenanceQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if([objects count] == 1) {
                if([[objects objectAtIndex:0][@"value"] isEqualToString:@"ON"]) {
                    MaintenanceViewController *maintenanceViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"MaintenanceViewController"];
                    [self presentViewController:maintenanceViewController animated:YES completion:NULL];
                }
            }
        }];
        
        // プッシュ通知用のデータがなければUserIdを突っ込んでおく
        [PushNotification setupPushNotificationInstallation];

        
        /*/////////////////////////////いちいちメール確認必要だから開発中はコメント//////////////////////////////////////
        // emailが確認されているか
        // まずはキャッシュからとる(verifiledされていればここで終わりなのでParseにとりにいかない)
        NSLog(@"currentUserStatus %@", _currentUser);
        if (![[_currentUser objectForKey:@"emailVerified"] boolValue]) {
            NSLog(@"Parseにフォアグランドでとりにいく");
            [_currentUser refresh];
            NSLog(@"refleshed currentUser %@", _currentUser);
            if (![[_currentUser objectForKey:@"emailVerified"] boolValue]) {
                NSLog(@"mailがまだ確認されていません");
                [self setNotVerifiedPage];
                return;
            }
        }
        //////////////////////////////////////////////////////////////////////////////*/
        
        // falimyIdを取得
        if (!_currentUser[@"familyId"] || [_currentUser[@"familyId"] isEqualToString:@""]) {
            NSLog(@"ログインしているけどファミリ- IDがない = 最初のログイン");
            IntroFirstViewController *introFirstViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"IntroFirstViewController"];
            //[self presentViewController:introFirstViewController animated:YES completion:NULL];
            [self.navigationController pushViewController:introFirstViewController animated:YES];
            return;
        }
        
        // nickname確認 なければ入れてもらう
        // まずはキャッシュから確認
        if (![_currentUser objectForKey:@"nickName"] || [[_currentUser objectForKey:@"nickName"] isEqualToString:@""]) {
            //キャッシュがなければフォアグランドで引いても良い。
            [_currentUser refresh];
            if (![_currentUser objectForKey:@"nickName"] || [[_currentUser objectForKey:@"nickName"] isEqualToString:@""]) {
                [self setMyNickNamePage];
                return;
            }
        }
        
        // roleを更新
        [FamilyRole updateCache];
        
        // Set if user has no child
        PFQuery *childQuery = [PFQuery queryWithClassName:@"Child"];
        [childQuery whereKey:@"familyId" equalTo:_currentUser[@"familyId"]];
        [childQuery orderByAscending:@"createdAt"];
        
        // networkから引く nwが駄目なら cacheから
        childQuery.cachePolicy = kPFCachePolicyNetworkElseCache;
        // 起動して一発目はfrontで引く
        if (_only_first_load == 1) {
            _childArrayFoundFromParse = [childQuery findObjects];
            [self setupChildProperties];
        
            // こどもが一人もいない = 一番最初のログインで一人目のこどもを作成しておく
            // こどもいるけどNW接続ないcacheないみたいな状況でここに入るとまずいか？
            if ([_childArrayFoundFromParse count] < 1) {
                [self setChildNames];
                return;
            }
            [self initializeChildImages];
            _only_first_load = 0;
            
            [_hud hide:YES];
        } else {
            // 二発目以降はbackgroundで引かないとUIが固まる
            [childQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if(!error) {
                    _childArrayFoundFromParse = objects;
                    [self initializeChildImages];
                }
            }];
        }
        [self showPageViewController];
    }
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


///////////////////////////////////////////////////////
// PFSignUpViewControllerのmethodたち
// Sent to the delegate to determine whether the sign up request should be submitted to the server.
// 以下のメソッドはLogin系と同じ
- (BOOL)signUpViewController:(PFSignUpViewController *)signUpController shouldBeginSignUp:(NSDictionary *)info {
    BOOL informationComplete = YES;
    
    // loop through all of the submitted data
    for (id key in info) {
        NSString *field = [info objectForKey:key];
        if (!field || field.length == 0) { // check completion
            informationComplete = NO;
            break;
        }
    }
     
    // Display an alert if a field wasn't completed
    if (!informationComplete) {
        [[[UIAlertView alloc] initWithTitle:@"Missing Information"
                              message:@"Make sure you fill out all of the information!"
                              delegate:nil
                              cancelButtonTitle:@"ok"
                              otherButtonTitles:nil] show];
    }
     
    return informationComplete;
}

// Sent to the delegate when a PFUser is signed up.
- (void)signUpViewController:(PFSignUpViewController *)signUpController didSignUpUser:(PFUser *)user {
    
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

// LoginViewを開く、各カスタムパラメータも設定
- (void)openLoginView
{
    // Create the log in view controller
    PFLogInViewController *logInViewController = [[PFLogInViewController alloc] init];
    [logInViewController setDelegate:self]; // Set ourselves as the delegate
    [logInViewController setFacebookPermissions:[NSArray arrayWithObjects:@"public_profile", nil]];
    [logInViewController setFields:
        PFLogInFieldsTwitter |
        PFLogInFieldsFacebook |
        PFLogInFieldsUsernameAndPassword |
        PFLogInFieldsPasswordForgotten |
        PFLogInFieldsLogInButton |
        PFLogInFieldsSignUpButton
    ];
    
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
    
    logInViewController.logInView.usernameField.placeholder = @"ユーザー名";
    logInViewController.logInView.passwordField.placeholder = @"パスワード";
     
    // Set field text color
    //[logInViewController.logInView.usernameField setTextColor:[UIColor colorWithRed:135.0f/255.0f green:118.0f/255.0f blue:92.0f/255.0f alpha:1.0]];
    //[logInViewController.logInView.passwordField setTextColor:[UIColor colorWithRed:135.0f/255.0f green:118.0f/255.0f blue:92.0f/255.0f alpha:1.0]];

    
    logInViewController.logInView.externalLogInLabel.text = @"ソーシャルアカウントでログイン";
    logInViewController.logInView.signUpLabel.text = @"";
    
    // Create the sign up view controller
    PFSignUpViewController *signUpViewController = [[PFSignUpViewController alloc] init];
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

- (void)openGlobalSettingView
{
    GlobalSettingViewController *globalSettingViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"GlobalSettingViewController"];
    [self.navigationController pushViewController:globalSettingViewController animated:YES];
}

- (void)setupChildProperties
{
    _childProperties = [[NSMutableArray alloc] init];
    for (PFObject *c in _childArrayFoundFromParse) {
        NSMutableDictionary *childSubDic = [[NSMutableDictionary alloc] init];
        [childSubDic setObject:c.objectId forKey:@"objectId"];
        [childSubDic setObject:c[@"name"] forKey:@"name"];
        if (c[@"birthday"]) {
            [childSubDic setObject:c[@"birthday"] forKey:@"birthday"];
        } else {
            [childSubDic setObject:[NSDate distantFuture] forKey:@"birthday"];
        }
        childSubDic[@"childImageShardIndex"] = c[@"childImageShardIndex"];
        childSubDic[@"createdAt"] = c.createdAt;
        [_childProperties addObject:childSubDic];
    }
}

-(void) showPageViewController
{
    if (!_pageViewController) {
        _pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PageViewController"];
        _pageViewController.childArray = _childProperties;
        [self addChildViewController:_pageViewController];
        [self.view addSubview:_pageViewController.view];
    }

    // global setting
    UIButton *openGlobalSettingButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    [openGlobalSettingButton setBackgroundImage:[UIImage imageNamed:@"listReverse"] forState:UIControlStateNormal];
    [openGlobalSettingButton addTarget:self action:@selector(openGlobalSettingView) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:openGlobalSettingButton];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
}

-(void)setNotVerifiedPage
{
    UIViewController *emailVerifiedViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NotEmailVerifiedViewController"];
    
    // リロードラベル
    UILabel *reloadLabel = [[UILabel alloc] init];
    reloadLabel.userInteractionEnabled = YES;
    reloadLabel.textAlignment = NSTextAlignmentCenter;
    reloadLabel.text = @"リロード";
    reloadLabel.textColor = [UIColor orangeColor];
    reloadLabel.layer.cornerRadius = 50;
    reloadLabel.layer.borderColor = [UIColor orangeColor].CGColor;
    reloadLabel.layer.borderWidth = 2.0f;
    CGRect frame = CGRectMake((self.view.frame.size.width - 100)/2, self.view.frame.size.height*2/3, 100, 100);
    reloadLabel.frame = frame;
    [emailVerifiedViewController.view addSubview:reloadLabel];
    
    UITapGestureRecognizer *stgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(reloadEmailVerifiedView:)];
    stgr.numberOfTapsRequired = 1;
    [reloadLabel addGestureRecognizer:stgr];
    
    [self presentViewController:emailVerifiedViewController animated:YES completion:NULL];
}

-(void)reloadEmailVerifiedView:(id)selector
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

-(void)setMyNickNamePage
{
    UIViewController *introMyNicknameViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"IntroMyNicknameViewController"];
    [self presentViewController:introMyNicknameViewController animated:YES completion:NULL];
}

-(void)setChildNames
{
    IntroChildNameViewController *introChildNameViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"IntroChildNameViewController"];
    [self presentViewController:introChildNameViewController animated:YES completion:NULL];
}

- (void)initializeChildImages
{
    _childImages = [[NSMutableDictionary alloc]init];
    for (PFObject *child in _childArrayFoundFromParse) {
        [_childImages setObject:[[NSMutableArray alloc]init] forKey:child.objectId];
    }
}


@end
