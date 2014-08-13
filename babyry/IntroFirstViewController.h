//
//  IntroFirstViewController.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/07/08.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface IntroFirstViewController : UIViewController <UIPageViewControllerDataSource>
@property (strong, nonatomic) IBOutlet UILabel *inviteLabel;
@property (strong, nonatomic) IBOutlet UILabel *invitedLabel;
@property (strong, nonatomic) IBOutlet UILabel *logout;
@property (weak, nonatomic) IBOutlet UIView *pageViewHeightBaseView;

@property (strong, nonatomic) UIPageViewController *pageViewController;
//@property (strong, nonatomic) UIViewController *introViewController;

@property int introPageIndex;

@property NSTimer *tm;

@property int applyCheckingFlag;

@end
