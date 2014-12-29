//
//  MyLogInViewController.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/08/17.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "MyLogInViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "ColorUtils.h"
#import "Logger.h"

@interface MyLogInViewController ()
@property (nonatomic, strong) UIImageView *fieldsBackground;
@end

@implementation MyLogInViewController

@synthesize fieldsBackground;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.logInView setBackgroundColor:[ColorUtils getBabyryColor]];
    [self.logInView setLogo:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@""]]];
    
    self.logInView.usernameField.backgroundColor = [ColorUtils getBackgroundColor];
    self.logInView.passwordField.backgroundColor = [ColorUtils getBackgroundColor];
    
    [self.logInView.logInButton setBackgroundColor:[UIColor grayColor]];
    [self.logInView.logInButton setBackgroundImage:nil forState:UIControlStateNormal];
    [self.logInView.logInButton setBackgroundImage:nil forState:UIControlStateHighlighted];
    
    [self.logInView.passwordForgottenButton setBackgroundColor:[UIColor clearColor]];
    [self.logInView.passwordForgottenButton setBackgroundImage:nil forState:UIControlStateNormal];
    [self.logInView.passwordForgottenButton setBackgroundImage:nil forState:UIControlStateHighlighted];
    [self.logInView.passwordForgottenButton setTitle:@"パスワードを忘れた方" forState:UIControlStateNormal];
    [self.logInView.passwordForgottenButton setTitle:@"パスワードを忘れた方" forState:UIControlStateHighlighted];
    
    [self.logInView.facebookButton setTitle:@"facebookアカウントでログイン" forState:UIControlStateNormal];
    [self.logInView.facebookButton setTitle:@"facebookアカウントでログイン" forState:UIControlStateHighlighted];
    [self.logInView.facebookButton setBackgroundColor:[ColorUtils getSatDayCalColor]];
    [self.logInView.facebookButton setBackgroundImage:nil forState:UIControlStateNormal];
    [self.logInView.facebookButton setBackgroundImage:nil forState:UIControlStateHighlighted];
    
//    [self.logInView.signUpButton setBackgroundColor:[ColorUtils getSunDayCalColor]];
//    [self.logInView.signUpButton setBackgroundImage:nil forState:UIControlStateNormal];
//    [self.logInView.signUpButton setBackgroundImage:nil forState:UIControlStateHighlighted];
    
    // Add login field background
    fieldsBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@""]];
    [self.logInView addSubview:self.fieldsBackground];
    [self.logInView sendSubviewToBack:self.fieldsBackground];
    
    self.logInView.externalLogInLabel.hidden = YES;
    self.logInView.signUpLabel.hidden = YES;
    
    self.logInView.usernameField.placeholder = @"メールアドレス";
    self.logInView.usernameField.keyboardType = UIKeyboardTypeEmailAddress;
    self.logInView.passwordField.placeholder = @"パスワード";
    self.logInView.passwordField.keyboardType = UIKeyboardTypeASCIICapable;
    
    // Remove text shadow
    CALayer *layer = self.logInView.usernameField.layer;
    layer.shadowOpacity = 0.0f;
    layer = self.logInView.passwordField.layer;
    layer.shadowOpacity = 0.0f;
    
    // Set field text color
    [self.logInView.usernameField setTextColor:[UIColor colorWithRed:135.0f/255.0f green:118.0f/255.0f blue:92.0f/255.0f alpha:1.0]];
    [self.logInView.passwordField setTextColor:[UIColor colorWithRed:135.0f/255.0f green:118.0f/255.0f blue:92.0f/255.0f alpha:1.0]];
    
    [Logger writeOneShot:@"info" message:@"LoginViewController is opened."];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    int frameHeight = self.view.frame.size.height*2/15;
    
    // Set frame for elements
    [self.logInView.dismissButton setFrame:CGRectMake(0.0f, 10.0f, 45.5f, 45.5f)];
    //[self.logInView.logo setFrame:CGRectMake(66.5f, 70.0f, 187.0f, 58.5f)];
    
    [self.logInView.usernameField setFrame:CGRectMake(35.0f, frameHeight * 2, 250.0f, frameHeight)];
    [self.logInView.passwordField setFrame:CGRectMake(35.0f, frameHeight * 3, 250.0f, frameHeight)];
    
    [self.logInView.logInButton setFrame:CGRectMake(35.0f, frameHeight * 4, 250.0f, 60.0f)];
    [self.logInView.passwordForgottenButton setFrame:CGRectMake(35.0f, self.logInView.logInButton.frame.origin.y + self.logInView.logInButton.frame.size.height, 250.0f, 40.0f)];
    
    [self.logInView.facebookButton setFrame:CGRectMake(35.0f, frameHeight * 6, 250.0f, 40.0f)];
    
//    [self.logInView.signUpButton setFrame:CGRectMake(35.0f, frameHeight * 6, 250.0f, 40.0f)];
    
    [self.fieldsBackground setFrame:CGRectMake(35.0f, 145.0f, 250.0f, 100.0f)];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
