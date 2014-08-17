//
//  IntroFirstViewController.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/07/08.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "IntroPageRootViewController.h"

@interface IntroFirstViewController : UIViewController <UIPageViewControllerDataSource, IntroPageRootViewControllerDelegate,PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate>

@property (strong, nonatomic) UIPageViewController *pageViewController;
@property int introPageIndex;
@property NSInteger currentPageControl;

- (void)openLoginView;
- (void)skipToLast:(NSInteger)currentIndex;

@end
