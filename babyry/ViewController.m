//
//  ViewController.m
//  babyrydev
//
//  Created by kenjiszk on 2014/05/30.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ViewController.h"
#import "ImageCache.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //NSLog(@"viewDidAppear@ViewController");
     
    if (![PFUser currentUser]) { // No user logged in
        //NSLog(@"No User Logged In");
        [self openLoginView];
    } else {
        //NSLog(@"Comeback! User logged in");
        // Set if user has no child
        PFQuery *childQuery = [PFQuery queryWithClassName:@"Child"];
        [childQuery whereKey:@"createdBy" equalTo:[PFUser currentUser]];
        NSArray *childArray = [childQuery findObjects];
        if ([childArray count] < 1) {
            //NSLog(@"make child");
            PFObject *child = [PFObject objectWithClassName:@"Child"];
            [child setObject:[PFUser currentUser] forKey:@"createdBy"];
            child[@"name"] = @"栽培マン1号";
            [child save];
        }
        // 再読み込み
        [self loadPages];
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
    //NSLog(@"didLogInUser");
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

// pragma mark - Page View Controller Data Source
// provides the view controller after the current view controller. In other words, we tell the app what to display for the next screen.
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger index = ((PageContentViewController*) viewController).pageIndex;
    
    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }
    
    index--;
    return [self viewControllerAtIndex:index];
}

// provides the view controller before the current view controller. In other words, we tell the app what to display when user switches back to the previous screen.
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = ((PageContentViewController*) viewController).pageIndex;
    
    if (index == NSNotFound) {
        return nil;
    }
    
    index++;
    if (index == [_childArray count]) {
        return nil;
    }
    return [self viewControllerAtIndex:index];
}

- (PageContentViewController *)viewControllerAtIndex:(NSUInteger)index
{
    //NSLog(@"index:%dのviewController", index);
    // 設定されたページが0か、indexがpageTitlesよりも多かったらnil返す
    if (([_childArray count] == 0) || (index >= [_childArray count])) {
        //NSLog(@"設定されたページが0か、indexがpageTitlesよりも多かったらnil返す");
        return nil;
    }
    
    // 新しいpageContentViewController返す
    // StoryBoardとひも付け
    //NSLog(@"StoryBoardとひも付け in viewControllerAtIndex");
    PageContentViewController *pageContentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PageContentViewController"];

    pageContentViewController.pageIndex = index;
    pageContentViewController.childArray = _childArray;
    
    return pageContentViewController;
}

// 全体で何ページあるか返す Delegate Method コメント外すとPageControlがあらわれる
/*
- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return [self.pageTitles count];
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    return 0;
}
*/

/*
- (IBAction)facebookButtonTapped:(id)sender {
    // 使いたいパーミッション指定
    NSArray *permissionsArray = @[ @"user_about_me", @"user_relationships", @"user_birthday", @"user_location"];
    // Facebook アカウントを使ってログイン
    [PFFacebookUtils logInWithPermissions:permissionsArray block:^(PFUser *user, NSError *error) {
        if (!user) {
            if (!error) {
                NSLog(@"Facebook ログインをユーザーがキャンセル");
            } else {
                NSLog(@"Facebook ログイン中にエラーが発生: %@", error);
            }
        } else if (user.isNew) {
            NSLog(@"Facebook サインアップ & ログイン完了!");
        } else {
            NSLog(@"Facebook ログイン完了!");
        }
    }];
}

- (IBAction)twitterButtonTapped:(id)sender {
    [PFTwitterUtils logInWithBlock:^(PFUser *user, NSError *error) {
        if (!user) {
            if (!error) {
                NSLog(@"Twitter ログインをユーザーがキャンセル");
            } else {
                NSLog(@"Twitter ログイン中にエラーが発生: %@", error);
            }
        } else if (user.isNew) {
            NSLog(@"Twitter サインアップ & ログイン完了!");
        } else {
            NSLog(@"Twitter ログイン完了!");
        }
    }];
}
*/

- (IBAction)startWalkthrough:(id)sender {
    PageContentViewController *startingViewController = [self viewControllerAtIndex:0];
    NSArray *viewControllers = @[startingViewController];
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionReverse animated:NO completion:nil];
}

// LoginViewを開く、各カスタムパラメータも設定
- (void)openLoginView
{
    // Create the log in view controller
    PFLogInViewController *logInViewController = [[PFLogInViewController alloc] init];
    [logInViewController setDelegate:self]; // Set ourselves as the delegate
    [logInViewController setFacebookPermissions:[NSArray arrayWithObjects:@"friends_about_me", nil]];
    [logInViewController setFields:
        PFLogInFieldsTwitter |
        PFLogInFieldsFacebook |
        PFLogInFieldsUsernameAndPassword |
        PFLogInFieldsPasswordForgotten |
        PFLogInFieldsDismissButton |
        PFLogInFieldsLogInButton |
        PFLogInFieldsSignUpButton
    ];

    //[logInViewController.logInView setBackgroundColor:[UIColor whiteColor]];
    //[logInViewController.logInView setLogo:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"BabyryLogo"]]];

    // Set buttons appearance
    //[logInViewController.logInView.dismissButton setImage:[UIImage imageNamed:@"exit.png"] forState:UIControlStateNormal];
    //[logInViewController.logInView.dismissButton setImage:[UIImage imageNamed:@"exit_down.png"] forState:UIControlStateHighlighted];
     
    //[logInViewController.logInView.facebookButton setImage:nil forState:UIControlStateNormal];
    //[logInViewController.logInView.facebookButton setImage:nil forState:UIControlStateHighlighted];
    //[logInViewController.logInView.facebookButton setBackgroundImage:[UIImage imageNamed:@"facebook_down.png"] forState:UIControlStateHighlighted];
    //[logInViewController.logInView.facebookButton setBackgroundImage:[UIImage imageNamed:@"facebook.png"] forState:UIControlStateNormal];
    //[logInViewController.logInView.facebookButton setTitle:@"" forState:UIControlStateNormal];
    //[logInViewController.logInView.facebookButton setTitle:@"" forState:UIControlStateHighlighted];
 
    //[logInViewController.logInView.twitterButton setImage:nil forState:UIControlStateNormal];
    //[logInViewController.logInView.twitterButton setImage:nil forState:UIControlStateHighlighted];
    //[logInViewController.logInView.twitterButton setBackgroundImage:[UIImage imageNamed:@"twitter.png"] forState:UIControlStateNormal];
    //[logInViewController.logInView.twitterButton setBackgroundImage:[UIImage imageNamed:@"twitter_down.png"] forState:UIControlStateHighlighted];
    //[logInViewController.logInView.twitterButton setTitle:@"" forState:UIControlStateNormal];
    //[logInViewController.logInView.twitterButton setTitle:@"" forState:UIControlStateHighlighted];
     
    //[logInViewController.logInView.signUpButton setBackgroundImage:[UIImage imageNamed:@"signup.png"] forState:UIControlStateNormal];
    //[logInViewController.logInView.signUpButton setBackgroundImage:[UIImage imageNamed:@"signup_down.png"] forState:UIControlStateHighlighted];
    //[logInViewController.logInView.signUpButton setTitle:@"" forState:UIControlStateNormal];
    //[logInViewController.logInView.signUpButton setTitle:@"" forState:UIControlStateHighlighted];
     
    // Add login field background
    //fieldsBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]];
    //[logInViewController.logInView insertSubview:fieldsBackground atIndex:1];
     
    // Remove text shadow
    //CALayer *layer = logInViewController.logInView.usernameField.layer;
    //layer.shadowOpacity = 0.0;
    //layer = logInViewController.logInView.passwordField.layer;
    //layer.shadowOpacity = 0.0;
     
    // Set field text color
    //[logInViewController.logInView.usernameField setTextColor:[UIColor colorWithRed:135.0f/255.0f green:118.0f/255.0f blue:92.0f/255.0f alpha:1.0]];
    //[logInViewController.logInView.passwordField setTextColor:[UIColor colorWithRed:135.0f/255.0f green:118.0f/255.0f blue:92.0f/255.0f alpha:1.0]];

    // Create the sign up view controller
    PFSignUpViewController *signUpViewController = [[PFSignUpViewController alloc] init];
    [signUpViewController setDelegate:self]; // Set ourselves as the delegate
         
    // Assign our sign up controller to be displayed from the login controller
    [logInViewController setSignUpController:signUpViewController];

    // Present the log in view controller
    [self presentViewController:logInViewController animated:YES completion:NULL];
}

- (void)addChild
{
    //NSLog(@"add child");
    int page_count = [_childArray count];
    //NSLog(@"page count %d", page_count);

    // Parseにchild追加
    PFObject *child = [PFObject objectWithClassName:@"Child"];
    [child setObject:[PFUser currentUser] forKey:@"createdBy"];
    child[@"name"] = [NSString stringWithFormat:@"栽培マン%d号", page_count + 1];
    [child saveInBackground];
    
    // 新規に足したpageに移動
    // page_count +1 だけど 0から始まるので +1はなし
    PageContentViewController *jumpViewController = [self viewControllerAtIndex:page_count];
    NSArray *viewControllers = @[jumpViewController];
    [_pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
}

-(void)logout
{
    [PFUser logOut];
    [self viewDidAppear:true];
}

-(void)loadPages
{
    // 今日の日付取得 ParseからChildImageを取得するため
    // ChildImageは、月ごとにChildImageYYYYMMというクラスに保存する
    // 全ておなじクラスに入れるとパフォーマンス問題が発生するのと、一度に1000件が取得maxのため
    // TODO この処理はNW状況によっては時間がかかるのでキャッシュ使うのと、backgroundで実行するようにする
    //NSLog(@"set date and month");
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMdd"];
    NSDate *date = [NSDate date];
    //NSString *dateStr = [formatter stringFromDate:date];
    // TopPage用に一週間の日付を取得しておく
    NSArray *weekDateArray = [[NSArray alloc] init];
    weekDateArray = @[];
    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comps = [cal components:NSYearCalendarUnit fromDate:date];
    for (int i = 0; i < 7; i++) {
        [comps setDay:-i];
        [comps setMonth:0];
        [comps setYear:0];
        NSDate *_date = [cal dateByAddingComponents:comps toDate:date options:0];
        //NSLog(@"%@ : %@", date, _date);
        NSString *_dateStr = [formatter stringFromDate:_date];
        weekDateArray = [weekDateArray arrayByAddingObject:_dateStr];
    }
    
    //NSLog(@"set user's data");
    _childArray = [[NSArray alloc] init];
    _childArray = @[];
    PFObject *currentUser = [PFUser currentUser];
    if (currentUser) {
        //NSLog(@"user exist. %@", currentUser.objectId);
        PFQuery *childQuery = [PFQuery queryWithClassName:@"Child"];
        [childQuery whereKey:@"createdBy" equalTo:currentUser];
        NSArray *childArrayFoundFromParse = [childQuery findObjects];
        // childが既にいる場合 もろもろデータ取得
        // childArray - index -- name (String)
        //                    |- images (UIImage in Array)
        //                    |- month (Array)
        //                    |- date (Array)
        //                    |- child.objectId (String)
        if ([childArrayFoundFromParse count] > 0) {
            //NSLog(@"Child exist.");
            // 同じ月を何度も引かないようにchildImageQueryを使い回す
            // TODO 月またぐと結局何度も引いちゃうからobjectをArrayに持たせる方が良いかもね
            NSString *monthAlreadySearched = @"no_date";
            for (PFObject *c in childArrayFoundFromParse) {
                NSMutableDictionary *childSubDic = [[NSMutableDictionary alloc] init];
                //NSLog(@"child id %@", c.objectId);
                // 名前取得、この配列がPageViewの数の元になる
                [childSubDic setObject:c[@"name"] forKey:@"name"];
                //NSLog(@"%@", c[@"name"]);
                
                // 各childにひもづく7日分のImageを取得
                NSArray *childImageArray = @[];
                NSArray *dateOfChildImageArray = @[];
                NSArray *monthOfChildImageArray = @[];
                // 月で取得したクエリ結果をキャッシュ
                NSArray *childMonthImageArray = [[NSArray alloc] init];
                // キャッシュ用object
                ImageCache *ic = [[ImageCache alloc]init];
                for (NSString *date in weekDateArray) {
                    // cache check
                    NSString *imageCachePath = [NSString stringWithFormat:@"%@%@", c.objectId, date];
                    NSData *imageCacheData = [ic getCache:imageCachePath];
                    //NSLog(@"date : %@", date);
                    // 日から月を取得
                    NSString *month = [date substringToIndex:6];
                    //NSLog(@"month : %@", month);
                
                    // 日、月代入
                    dateOfChildImageArray = [dateOfChildImageArray arrayByAddingObject:date];
                    monthOfChildImageArray = [monthOfChildImageArray arrayByAddingObject:month];
                    
                    if (!imageCacheData) {
                        // 以前取得したmonthと異なる場合(月またぎ) クエリを取得し直す
                        if (![monthAlreadySearched isEqualToString:month]) {
                            //NSLog(@"not much! get monthry childimage. monthAlreadySearched:%@ month:%@", monthAlreadySearched, month);
                            // ChildImageYYYYMM をえらびーの
                            PFQuery *childMonthImageQuery = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%@", month]];
                            // imageOf = childId をひきーの
                            [childMonthImageQuery whereKey:@"imageOf" equalTo:c.objectId];
                            childMonthImageArray = [childMonthImageQuery findObjects];
                            monthAlreadySearched = month;
                        }
                        // dateと一致するobjectを見つけたら格納
                        int notFoundInParse = 0;
                        for (PFObject *ci in childMonthImageArray) {
                            //NSLog(@"comparison %@ : %@", ci[@"date"], date);
                            if ([ci[@"date"] isEqualToString:[NSString stringWithFormat:@"D%@", date]]) {
                                //NSLog(@"found image");
                                //NSLog(@"%@", ci[@"imageFile"]);
                                if(ci[@"imageFile"]) {
                                    NSData *tmpImageData = [ci[@"imageFile"] getData];
                                    childImageArray = [childImageArray arrayByAddingObject:[UIImage imageWithData:tmpImageData]];
                                } else {
                                    // 何らかの理由で画像だけ消されている場合
                                    childImageArray = [childImageArray arrayByAddingObject:[UIImage imageNamed:@"NoImage"]];
                                }
                                notFoundInParse = 1;
                            }
                        }
                        // notFoundInParseが0 : 画像がParseに無い NoImageつっこむ
                        if (notFoundInParse == 0) {
                            //NSLog(@"no element in childMonthImageArray");
                            childImageArray = [childImageArray arrayByAddingObject:[UIImage imageNamed:@"NoImage"]];
                        }
                    } else {
                        //NSLog(@"cache found!!!");
                        // cacheDataを突っ込む
                        childImageArray = [childImageArray arrayByAddingObject:[[UIImage alloc] initWithData:imageCacheData]];
                    }
                }
                [childSubDic setObject:childImageArray forKey:@"images"];
                [childSubDic setObject:dateOfChildImageArray forKey:@"date"];
                [childSubDic setObject:monthOfChildImageArray forKey:@"month"];
                [childSubDic setObject:c.objectId forKey:@"objectId"];
                _childArray = [_childArray arrayByAddingObject:childSubDic];
                //NSLog(@"childSubDic : %d, childArray : %d", [childSubDic count], [_childArray count]);
            }
        } else {
            // childいない場合
            //NSLog(@"no child");
            // いない事はまずあり得ない。
            // User作った段階で一人childつくるから
            // 万が一ここに遷移した時のために一人目のchildを作る必要があるかも(TODO)
        }
    } else {
        // currentUserがいない場合でもなにか表示する?
        //NSLog(@"no user");
        // currentUserがいない。ログインしていない。
        // それでもchildArrayにダミーデータを入れておかないと起動時に落ちる
        // 本来はこのケースでは空のViewを出す方が良い (TODO)
        NSMutableDictionary *childSubDic = [[NSMutableDictionary alloc] init];
        [childSubDic setObject:@"栽培マン1号" forKey:@"name"];
        _childArray = [_childArray arrayByAddingObject:childSubDic];
    }
    
    //NSLog(@"make pages");
        
    // Create page view controller
    //NSLog(@"storyboardのPageViewControllerのidとひも付け");
    _pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PageViewController"];
    _pageViewController.dataSource = self;
    
    //NSLog(@"0ページ目を表示");
    PageContentViewController *startingViewController = [self viewControllerAtIndex:0];
    NSArray *viewControllers = @[startingViewController];
    [_pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    // Change the size of page view controller
    //NSLog(@"view controllerのサイズ変更");
    _pageViewController.view.frame = CGRectMake(0, 44, self.view.frame.size.width, self.view.frame.size.height);
    
    //NSLog(@"view追加");
    [self addChildViewController:_pageViewController];
    [self.view addSubview:_pageViewController.view];
    [_pageViewController didMoveToParentViewController:self];
    
    // +ボタンがなぜかでないけどスルー
    //NSLog(@"addChild ボタン追加");
    (void)[self.addNewChildButton initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addChild)];
    
    // logoutButton
    //NSLog(@"logout ボタン追加");
    (void)[self.logoutButton initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(logout)];
}

@end
