//
//  IntroFirstViewController.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/07/08.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "IntroFirstViewController.h"
#import "UIViewController+MJPopupViewController.h"
#import "FamilyApplyListViewController.h"
#import "IdIssue.h"
#import "IntroPageRootViewController.h"
#import "UIColor+Hex.h"
#import <QuartzCore/QuartzCore.h>
#import "ColorUtils.h"
#import "MyLogInViewController.h"
#import "MySignUpViewController.h"
#import "Logger.h"
#import "PartnerInvitedEntity.h"
#import "ChooseRegisterStepViewController.h"

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
    _pageViewController.delegate = self;
    
    UIViewController *startingViewController = [self viewControllerAtIndex:0];
    _currentPageControl = 0;
    NSArray *viewControllers = @[startingViewController];
    [_pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    [self addChildViewController:_pageViewController];
    [self.view addSubview:_pageViewController.view];
    [_pageViewController didMoveToParentViewController:self];
   
    _pageControl.numberOfPages = 5;
    CGRect controlFrame = _pageControl.frame;
    controlFrame.size.height = 27;
    controlFrame.origin.y = self.view.frame.size.height - 27;
    _pageControl.frame = controlFrame;
    [_pageControl setBackgroundColor:[UIColor clearColor]];
    _pageControl.pageIndicatorTintColor = [UIColor grayColor];
    _pageControl.currentPageIndicatorTintColor = [UIColor whiteColor];
    [self.view addSubview:_pageControl.viewForBaselineLayout];
    _pageControl.currentPage = 0;
//    // pageController
//    NSArray *subviews = _pageViewController.view.subviews;
//    UIPageControl *thisControl = nil;
//    for (int i=0; i<[subviews count]; i++) {
//        if ([[subviews objectAtIndex:i] isKindOfClass:[UIPageControl class]]) {
//            thisControl = (UIPageControl *)[subviews objectAtIndex:i];
//            [thisControl setBackgroundColor:[UIColor clearColor]];
//            //thisControl.backgroundColor = [UIColor_Hex colorWithHexString:@"666666" alpha:0.0];
//            //thisControl.pageIndicatorTintColor = [UIColor grayColor];
//            //thisControl.currentPageIndicatorTintColor = [UIColor whiteColor];
//        }
//    }
    
    [Logger writeOneShot:@"info" message:@"Not-Login User Opend IntroFirstViewController"];
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
        vc = [self.storyboard instantiateViewControllerWithIdentifier:@"IntroPageSixthViewController"];
    }
    vc.delegate = self;
    vc.currentIndex = index;
    vc.view.tag = index;
    
    return vc;
}

// 全体で何ページあるか返す Delegate Method コメント外すとPageControlがあらわれる
//
//- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
//{
//    return 6;
//}
// 
//- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
//{
//    return _currentPageControl;
//}
///////////////////////////////////////

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    IntroPageRootViewController *currentView = [pageViewController.viewControllers objectAtIndex:0];
    _pageControl.currentPage = currentView.currentIndex;
}

- (void)skipToLast:(NSInteger)currentIndex
{
    NSInteger waitIndex = 0;
    for (NSInteger i = currentIndex+1; i <= 4; i++) {
        CGFloat interval = 0.1 * waitIndex;
        NSNumber *n = [NSNumber numberWithInteger:i];
        NSMutableDictionary *info = [[NSMutableDictionary alloc]initWithObjects:@[n] forKeys:@[@"index"]];
        [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(nextPage:) userInfo:info repeats:NO];
        waitIndex++;
        _pageControl.currentPage = i;
    }
}

- (void)nextPage:(NSTimer *)timer
{
    NSMutableDictionary *info = timer.userInfo;
    NSInteger index = [info[@"index"] integerValue];
    [_pageViewController setViewControllers:@[ [self viewControllerAtIndex:index] ] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
}

@end
