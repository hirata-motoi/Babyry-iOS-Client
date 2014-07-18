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
    
    _applyCheckingFlag = 0;
    
    _introPageIndex = 0;
    // PageViewController追加
    _pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    _pageViewController.dataSource = self;
    
    CGRect frame = _pageViewController.view.frame;
    frame.size.height = self.view.frame.size.height*2/3;
    _pageViewController.view.frame = frame;
    
    NSLog(@"0ページ目を表示");
    UIViewController *startingViewController = [self viewControllerAtIndex:0];
    NSArray *viewControllers = @[startingViewController];
    [_pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    [self addChildViewController:_pageViewController];
    [self.view addSubview:_pageViewController.view];
    [_pageViewController didMoveToParentViewController:self];
    
    // Add Listener
    _inviteLabel.tag = 1;
    UITapGestureRecognizer *singleTapGestureRecognizer1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    singleTapGestureRecognizer1.numberOfTapsRequired = 1;
    [_inviteLabel addGestureRecognizer:singleTapGestureRecognizer1];
    
    
    _invitedLabel.tag = 2;
    UITapGestureRecognizer *singleTapGestureRecognizer2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    singleTapGestureRecognizer2.numberOfTapsRequired = 1;
    [_invitedLabel addGestureRecognizer:singleTapGestureRecognizer2];
    
    // add gesture on self.view
    UITapGestureRecognizer *singleTapGestureRecognizer0 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    singleTapGestureRecognizer0.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:singleTapGestureRecognizer0];

    [self checkFamilyApply:_tm];
    
    _tm = [NSTimer scheduledTimerWithTimeInterval:30.0f target:self selector:@selector(checkFamilyApply:) userInfo:nil repeats:YES];
    [_tm fire];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // check this acount has family Id or not
    if ([PFUser currentUser][@"familyId"]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    if (![_tm isValid]) {
        [_tm fire];
    }
}

- (void) viewDidDisappear:(BOOL)animated
{
    [_tm invalidate];
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

-(void)handleSingleTap:(id) sender
{
    int tag = [[sender view] tag];
    if (tag == 1) {
        UIViewController *inviteViewController = [[UIViewController alloc] init];
        float x = (self.view.frame.size.width - 200)/2;
        inviteViewController.view.frame = CGRectMake(x, 50.0f, 200.0f, 200.0f);
        inviteViewController.view.backgroundColor = [UIColor whiteColor];
        [self presentPopupViewController:inviteViewController animationType:MJPopupViewAnimationFade];
        
        // ラベル付ける
        UILabel *inviteByLineLabel = [[UILabel alloc] init];
        inviteByLineLabel.frame = CGRectMake(25, 40, 150, 40);
        inviteByLineLabel.backgroundColor = [UIColor colorWithRed:0.4 green:1.0 blue:0.4 alpha:1.0];
        inviteByLineLabel.text = @"LINEで招待";
        inviteByLineLabel.textColor = [UIColor whiteColor];
        inviteByLineLabel.textAlignment = NSTextAlignmentCenter;
        inviteByLineLabel.tag = 3;
        inviteByLineLabel.userInteractionEnabled = YES;
        UITapGestureRecognizer *singleTapGestureRecognizer3 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
        singleTapGestureRecognizer3.numberOfTapsRequired = 1;
        [inviteByLineLabel addGestureRecognizer:singleTapGestureRecognizer3];
        [inviteViewController.view addSubview:inviteByLineLabel];
        
        UILabel *inviteByMailLabel = [[UILabel alloc] init];
        inviteByMailLabel.frame = CGRectMake(25, 120, 150, 40);
        inviteByMailLabel.backgroundColor = [UIColor colorWithRed:0.4 green:0.4 blue:1.0 alpha:1.0];
        inviteByMailLabel.text = @"メールで招待";
        inviteByMailLabel.textColor = [UIColor whiteColor];
        inviteByMailLabel.textAlignment = NSTextAlignmentCenter;
        inviteByMailLabel.tag = 4;
        inviteByMailLabel.userInteractionEnabled = YES;
        UITapGestureRecognizer *singleTapGestureRecognizer4 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
        singleTapGestureRecognizer4.numberOfTapsRequired = 1;
        [inviteByMailLabel addGestureRecognizer:singleTapGestureRecognizer4];
        [inviteViewController.view addSubview:inviteByMailLabel];
    } else if (tag == 2) {
        FamilyApplyViewController * familyApplyViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"FamilyApplyViewController"];
        [self presentViewController:familyApplyViewController animated:YES completion:NULL];
    } else if (tag == 3 || tag == 4) {
        NSString *plainTitle = @"Babyryへ招待";
        NSString *escapedUrlTitle = [plainTitle stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        NSString *plainText = [NSString stringWithFormat:@"Babyryに招待します。\n以下のURLからアプリをインストール後、ユーザーID %@ を入力してください。\nhttps://app.store/id=3333",     [PFUser currentUser][@"userId"]];
        NSString *escapedUrlText = [plainText stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSLog(@"%@", escapedUrlText);
        if (tag == 3) {
            NSLog(@"tap LINE invite");
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"line://msg/text/%@", escapedUrlText]]];
            [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
        } else {
            NSLog(@"tap Mail invite");
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"mailto:?Subject=%@&body=%@", escapedUrlTitle, escapedUrlText]]];
            [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
        }
    } else {
        [self.view endEditing:YES];
    }
}

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

- (void) checkFamilyApply:(NSTimer*)timer
{
    // 排他処理
    if (_applyCheckingFlag == 1) {
        return;
    } else {
        _applyCheckingFlag = 1;
    }
    
    PFQuery *familyApplyQuery = [PFQuery queryWithClassName:@"FamilyApply"];
    [familyApplyQuery whereKey:@"inviteeUserId" equalTo:[PFUser currentUser][@"userId"]];
    [familyApplyQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if([objects count] > 0){
            NSLog(@"extist in familyAppy as inviteeUserId");
            FamilyApplyListViewController *familyApplyListViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"FamilyApplyListViewController"];
            NSLog(@"%@", familyApplyListViewController);
            [self presentViewController:familyApplyListViewController animated:true completion:nil];
            _applyCheckingFlag = 0;
        }
    }];
}

@end
