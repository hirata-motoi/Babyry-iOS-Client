//
//  ViewController.m
//  babyrydev
//
//  Created by kenjiszk on 2014/05/30.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ViewController.h"
#import "ImageCache.h"
#import "Sequence.h"
#import "EtcViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    NSLog(@"viewDidLoad");
    
    // くるくる
    _indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    float w = _indicator.frame.size.width;
    float h = _indicator.frame.size.height;
    float x = self.view.frame.size.width/2 - w/2;
    float y = self.view.frame.size.height/2 - h/2;
    _indicator.frame = CGRectMake(x, y, w, h);
    _indicator.hidesWhenStopped = YES;
    [_indicator startAnimating];
    [self.view addSubview:_indicator];
    
    _only_first_load = 1;
    _is_return_from_upload = 0;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"viewDidAppear _only_first_load : %d _is_return_from_upload : %d", _only_first_load, _is_return_from_upload);
    
    _currentUser = [PFUser currentUser];
    if (!_currentUser) { // No user logged in
        NSLog(@"User Not Logged In");
        [self openLoginView];
    } else {
        NSLog(@"Comeback! User logged in user_id:%@", _currentUser.objectId);
        // falimyIdを取得
        NSLog(@"%@", _currentUser);
        NSLog(@"familyId is %@", _currentUser[@"familyId"]);
        if (!_currentUser[@"familyId"]) {
            NSLog(@"No FamilyId! これはありえないけど何らかの処理を入れないと駄目");
        }
        
        // Set if user has no child
        PFQuery *childQuery = [PFQuery queryWithClassName:@"Child"];
        [childQuery whereKey:@"familyId" equalTo:_currentUser[@"familyId"]];
        [childQuery orderByAscending:@"createdAt"];
        
        // networkから引く nwが駄目なら cacheから
        childQuery.cachePolicy = kPFCachePolicyNetworkElseCache;
        // 起動して一発目はfrontで引く
        if (_only_first_load == 1) {
            _childArrayFoundFromParse = [childQuery findObjects];
        
            // こどもが一人もいない = 一番最初のログインで一人目のこどもを作成しておく
            // こどもいるけどNW接続ないcacheないみたいな状況でここに入るとまずいか？
            if ([_childArrayFoundFromParse count] < 1) {
                //NSLog(@"make child");
                PFObject *child = [PFObject objectWithClassName:@"Child"];
                [child setObject:_currentUser forKey:@"createdBy"];
                child[@"name"] = @"栽培マン1号";
                child[@"familyId"] = _currentUser[@"familyId"];
                [child save];
            }
            // まずはCacheからオフラインでも表示出来るものを先に表示
            [self getWeekDate];
            [self getCachedImage];
            [self getParseData];
            _only_first_load = 0;
        } else {
            // 二発目以降はbackgroundで引かないとUIが固まる
            [childQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if(!error) {
                    _childArrayFoundFromParse = objects;
                    // Parseにアクセスして最新の情報を取得
                    NSLog(@"update pictures");
                    [self getWeekDate];
                    [self getCachedImage];
                    // uploadから復帰する時はParseからとらない
                    // parseの更新が遅延している可能性があるため
                    if (_is_return_from_upload == 0) {
                        [self getParseData];
                        _is_return_from_upload = 0;
                    }
                }
            }];
        }
    }
    [_indicator stopAnimating];
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
    
    // user_idを発行して保存
    Sequence * seq = [[Sequence alloc]init];
    NSNumber * userIdNum = [seq issueSequenceId:@"user_id"];
    NSLog(@"sequence id succeeded  id:%@", userIdNum);
    
    
    user[@"userId"] = userIdNum;
    [user saveInBackground];
    
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

- (IBAction)logoutButton:(id)sender {
    [PFUser logOut];
    [self viewDidAppear:true];
}

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
    [child setObject:_currentUser forKey:@"createdBy"];
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

-(void)openEtc
{
    EtcViewController * etcViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"etcViewController"];
    [self presentViewController:etcViewController animated:true completion:nil];
}

- (void) getWeekDate
{
    NSLog(@"setWeekDate");
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMdd"];
    NSDate *date = [NSDate date];
    //NSString *dateStr = [formatter stringFromDate:date];
    // TopPage用に日付を取得しておく
    _weekDateArray = [[NSArray alloc] init];
    _weekDateArray = @[];
    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comps = [cal components:NSYearCalendarUnit fromDate:date];
    for (int i = 0; i < 7; i++) {
        [comps setDay:-i];
        [comps setMonth:0];
        [comps setYear:0];
        NSDate *_date = [cal dateByAddingComponents:comps toDate:date options:0];
        //NSLog(@"%@ : %@", date, _date);
        NSString *_dateStr = [formatter stringFromDate:_date];
        _weekDateArray = [_weekDateArray arrayByAddingObject:_dateStr];
    }
}

- (void) getCachedImage
{
    NSLog(@"getCachedImage");
    // オフラインでもトップは見れるようにキャッシュから画像取得
    // こども毎にキャッシュ画像格納
    int childIndex = 0;
    _childArray = [[NSMutableArray alloc] init];
    for (PFObject *c in _childArrayFoundFromParse) {
        NSMutableDictionary *childSubDic = [[NSMutableDictionary alloc] init];
        // 一週間分
        int weekIndex = 0;
        NSString *imageCachePath;
        NSData *imageCacheData;
        NSMutableArray *childImageArray = [[NSMutableArray alloc] init];
        NSMutableArray *dateOfChildImageArray = [[NSMutableArray alloc] init];
        NSMutableArray *monthOfChildImageArray = [[NSMutableArray alloc] init];
        NSMutableArray *bestFlagOfChildImageArray = [[NSMutableArray alloc] init];
        for (NSString *date in _weekDateArray) {
            [dateOfChildImageArray insertObject:date atIndex:weekIndex];
            imageCachePath = [NSString stringWithFormat:@"%@%@", c.objectId, date];
            imageCacheData = [ImageCache getCache:imageCachePath];
            if(imageCacheData) {
                [childImageArray insertObject:[UIImage imageWithData:imageCacheData] atIndex:weekIndex];
            } else {
                [childImageArray insertObject:[UIImage imageNamed:@"NoImage"] atIndex:weekIndex];
            }
            [bestFlagOfChildImageArray insertObject:@"noflag" atIndex:weekIndex];
            NSString *month = [date substringToIndex:6];
            [monthOfChildImageArray insertObject:month atIndex:weekIndex];
            weekIndex++;
        }
        [childSubDic setObject:c.objectId forKey:@"objectId"];
        [childSubDic setObject:c[@"name"] forKey:@"name"];
        if (c[@"birthday"]) {
            [childSubDic setObject:c[@"birthday"] forKey:@"birthday"];
        } else {
            [childSubDic setObject:[NSDate distantFuture] forKey:@"birthday"];
        }
        [childSubDic setObject:bestFlagOfChildImageArray forKey:@"bestFlag"];
        [childSubDic setObject:dateOfChildImageArray forKey:@"date"];
        [childSubDic setObject:monthOfChildImageArray forKey:@"month"];
        [childSubDic setObject:childImageArray forKey:@"images"];
        [_childArray insertObject:childSubDic atIndex:childIndex];
        childIndex++;
    }
    //NSLog(@"%@", _childArray);
    [self setPage];
}

-(void) getParseData
{
    NSLog(@"getParseData");
    // Parseから最新データととる
    
    // 一週間表示用のmonth配列を作成
    NSArray *monthArrayForQuery = [[NSArray alloc] init];
    NSString *searchedMonth = @"no_data";
    for (NSString *date in _weekDateArray) {
        NSString *month = [date substringToIndex:6];
        if (![month isEqual:searchedMonth]) {
            monthArrayForQuery = [monthArrayForQuery arrayByAddingObject:month];
            searchedMonth = month;
        }
    }
    NSLog(@"%@", monthArrayForQuery);

    for (PFObject *c in _childArrayFoundFromParse) {
        for (NSString *month in monthArrayForQuery) {
            PFQuery *childMonthImageQuery = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%@", month]];
            childMonthImageQuery.cachePolicy = kPFCachePolicyNetworkOnly;
            [childMonthImageQuery whereKey:@"imageOf" equalTo:c.objectId];
            // choosed(bestShot)を探す
            [childMonthImageQuery whereKey:@"bestFlag" equalTo:@"choosed"];
            [childMonthImageQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if(!error) {
                    if ([objects count] == 0) {
                        //NSLog(@"no image in %@ %@", c[@"name"], month);
                    } else if ([objects count] > 0) {
                        //NSLog(@"image found in %@ %@", c[@"name"], month);
                        for (PFObject *object in objects) {
                            // Parseから持って来たデータでchildArray更新する
                            // (階層が深くなってきて気持ち悪いけどbackgroundだから良いかなと。。。)
                            // childArray - index -- name (String)
                            //                    |- bestFlag (Array)
                            //                    |- images (UIImage in Array)
                            //                    |- month (Array)
                            //                    |- date (Array)
                            //                    |- child.objectId (String)
                            //                    |- birthday (Date)
                            //NSLog(@"%@ %@ %@", object[@"date"], object[@"bestFlag"], object.objectId);
                            int cIndex = 0;
                            NSMutableDictionary *tmpDic = [[NSMutableDictionary alloc] init];
                            for (PFObject *c in _childArrayFoundFromParse) {
                                if ([c.objectId isEqual:object[@"imageOf"]]) {
                                    tmpDic = [_childArray objectAtIndex:cIndex];
                                    int wIndex = 0;
                                    for (NSString *date in _weekDateArray) {
                                        if ([object[@"date"] isEqual:[NSString stringWithFormat:@"D%@", date]]) {
                                            //NSLog(@"much! %@ %@ %d", object[@"date"], date, wIndex);
                                            [[tmpDic objectForKey:@"bestFlag"] setObject:object[@"bestFlag"] atIndex:wIndex];
                                            //NSLog(@"ここでParseに接続。全部backgroundにする");
                                            [object[@"imageFile"] getDataInBackgroundWithBlock:^(NSData *data, NSError *error){
                                                if(!error){
                                                    [[tmpDic objectForKey:@"images"] setObject:[UIImage imageWithData:data] atIndex:wIndex];
                                                    // bestshotはローカルキャッシュに保存しておく
                                                    [ImageCache setCache:[NSString stringWithFormat:@"%@%@", c.objectId, date] image:data];
                                                    
                                                    // 画像update毎回やるから負荷たかいかな
                                                    // TODO : contentviewのviewに直接アクセスして画像をはめ込むようにするべき
                                                    [_childArray replaceObjectAtIndex:cIndex withObject:tmpDic];
                                                    PageContentViewController *startingViewController = [self viewControllerAtIndex:_currentPageIndex];
                                                    NSArray *viewControllers = @[startingViewController];
                                                    [_pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
                                                }
                                            }];
                                        }
                                        wIndex++;
                                    }
                                }
                                cIndex++;
                            }
                        }
                    }
                }
            }];
        }
    }
}

-(void) setPage
{
    if (_only_first_load == 1) {
        //NSLog(@"reflectChildArray");
        //NSLog(@"storyboardのPageViewControllerのidとひも付け");
        _pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PageViewController"];
        _pageViewController.dataSource = self;
    
        //NSLog(@"0ページ目を表示");
        PageContentViewController *startingViewController = [self viewControllerAtIndex:0];
        NSArray *viewControllers = @[startingViewController];
        [_pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
        // Change the size of page view controller
        //NSLog(@"view controllerのサイズ変更");
        _pageViewController.view.frame = CGRectMake(0, 50, self.view.frame.size.width, self.view.frame.size.height);
    
        //NSLog(@"view追加");
        [self addChildViewController:_pageViewController];
        [self.view addSubview:_pageViewController.view];
        [_pageViewController didMoveToParentViewController:self];
    
        // +ボタンがなぜかでないけどスルー
        //NSLog(@"addChild ボタン追加");
        //(void)[self.addNewChildButton initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addChild)];
    
        // logoutButton
        NSLog(@"etc open ボタン追加");
        [self.openEtcButton addTarget:self action:@selector(openEtc) forControlEvents:UIControlEventTouchUpInside];
    } else {
        PageContentViewController *startingViewController = [self viewControllerAtIndex:_currentPageIndex];
        NSArray *viewControllers = @[startingViewController];
        [_pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    }
}

@end
