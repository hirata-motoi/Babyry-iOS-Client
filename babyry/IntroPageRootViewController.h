//
//  IntroPageRootViewController.h
//  babyry
//
//  Created by hirata.motoi on 2014/08/17.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "MyLogInViewController.h"

@protocol IntroPageRootViewControllerDelegate <NSObject>
- (void)skipToLast:(NSInteger)currentIndex;
@end

@interface IntroPageRootViewController : UIViewController<PFLogInViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *skipFromFirst;
@property (weak, nonatomic) IBOutlet UILabel *skipFromSecond;
@property (weak, nonatomic) IBOutlet UILabel *skipFromThird;
@property (weak, nonatomic) IBOutlet UILabel *skipFromFourth;
@property (strong, nonatomic) IBOutlet UILabel *skipFromFifth;
@property (strong, nonatomic) IBOutlet UILabel *invitedButton;
@property (strong, nonatomic) IBOutlet UILabel *registerButton;
@property (strong, nonatomic) IBOutlet UILabel *loginButton;

@property NSInteger currentIndex;

@property (nonatomic,assign) id<IntroPageRootViewControllerDelegate> delegate;

- (void)openLoginView;
- (void)showRegisterStepCheckView;

@end
