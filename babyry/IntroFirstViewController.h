//
//  IntroFirstViewController.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/07/08.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface IntroFirstViewController : UIViewController <UIPageViewControllerDataSource, PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate>

@property (strong, nonatomic) UIPageViewController *pageViewController;
@property int introPageIndex;
@property (strong, nonatomic) IBOutlet UIButton *registerButton;
- (IBAction)registerAction:(id)sender;

@end
