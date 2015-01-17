//
//  MySignUpViewController.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/08/17.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "MySignUpViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "ColorUtils.h"
#import "Logger.h"

@interface MySignUpViewController ()
@property (nonatomic, strong) UIImageView *fieldsBackground;
@end

@implementation MySignUpViewController

@synthesize fieldsBackground;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.signUpView setBackgroundColor:[ColorUtils getBabyryColor]];
    [self.signUpView setLogo:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@""]]];
    
    [self.signUpView.signUpButton setBackgroundColor:[UIColor grayColor]];
    [self.signUpView.signUpButton setBackgroundImage:nil forState:UIControlStateNormal];
    [self.signUpView.signUpButton setBackgroundImage:nil forState:UIControlStateHighlighted];
    
    self.signUpView.usernameField.backgroundColor = [ColorUtils getBackgroundColor];
    self.signUpView.usernameField.placeholder = @"メールアドレス";
    self.signUpView.usernameField.keyboardType = UIKeyboardTypeEmailAddress;
    
    self.signUpView.passwordField.backgroundColor = [ColorUtils getBackgroundColor];
    self.signUpView.passwordField.placeholder = @"パスワード";
    self.signUpView.passwordField.keyboardType = UIKeyboardTypeASCIICapable;
    
    self.signUpView.additionalField.backgroundColor = [ColorUtils getBackgroundColor];
    self.signUpView.additionalField.placeholder = @"パスワード(確認)";
    self.signUpView.additionalField.keyboardType = UIKeyboardTypeASCIICapable;
    self.signUpView.additionalField.secureTextEntry = YES;    
    
    // Remove text shadow
    CALayer *layer = self.signUpView.usernameField.layer;
    layer.shadowOpacity = 0.0f;
    layer = self.signUpView.passwordField.layer;
    layer.shadowOpacity = 0.0f;
    layer = self.signUpView.emailField.layer;
    layer.shadowOpacity = 0.0f;
    layer = self.signUpView.additionalField.layer;
    layer.shadowOpacity = 0.0f;
    
    // Set text color
    [self.signUpView.usernameField setTextColor:[UIColor colorWithRed:135.0f/255.0f green:118.0f/255.0f blue:92.0f/255.0f alpha:1.0]];
    [self.signUpView.passwordField setTextColor:[UIColor colorWithRed:135.0f/255.0f green:118.0f/255.0f blue:92.0f/255.0f alpha:1.0]];
    [self.signUpView.emailField setTextColor:[UIColor colorWithRed:135.0f/255.0f green:118.0f/255.0f blue:92.0f/255.0f alpha:1.0]];
    [self.signUpView.additionalField setTextColor:[UIColor colorWithRed:135.0f/255.0f green:118.0f/255.0f blue:92.0f/255.0f alpha:1.0]];
    
    [Logger writeOneShot:@"info" message:@"SignUpViewController is opened."];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    int frameHeight = self.view.frame.size.height*2/15;
    
    [self.signUpView.usernameField setFrame:CGRectMake(35.0f, frameHeight*2, 250.0f, frameHeight)];
    [self.signUpView.passwordField setFrame:CGRectMake(35.0f, frameHeight*3, 250.0f, frameHeight)];
    [self.signUpView.additionalField setFrame:CGRectMake(35.0f, frameHeight*4, 250.0f, frameHeight)];
    [self.signUpView.signUpButton setFrame:CGRectMake(35.0f, frameHeight*5, 250.0f, 60.0f)];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
