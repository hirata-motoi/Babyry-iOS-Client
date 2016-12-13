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
#import "CloseButtonView.h"

@interface MySignUpViewController ()
@property (nonatomic, strong) UIImageView *fieldsBackground;
@end

@implementation MySignUpViewController
{
    UILabel *signUpViewTitle;
    CloseButtonView *buttonView;
}

@synthesize fieldsBackground;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.signUpView setBackgroundColor:[ColorUtils getBabyryColor]];
    [self.signUpView setLogo:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@""]]];
    
    // デフォのアイコンがただの×なので変える
    self.signUpView.dismissButton.hidden = YES;
    buttonView = [CloseButtonView view];
    [self.view addSubview:buttonView];
    UITapGestureRecognizer *dismisGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(dismisViewController)];
    dismisGesture.numberOfTapsRequired = 1;
    [buttonView addGestureRecognizer:dismisGesture];
    
    // タイトル
    signUpViewTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 50, 320, 44)];
    signUpViewTitle.font = [UIFont fontWithName:@"HiraKakuProN-W6" size:20.0f];
    signUpViewTitle.textAlignment = NSTextAlignmentCenter;
    signUpViewTitle.textColor = [ColorUtils getIntroDarkGrayStringColor];
    signUpViewTitle.text = @"会員登録";
    [self.signUpView addSubview:signUpViewTitle];
    
    [self.signUpView.signUpButton setBackgroundColor:[ColorUtils getPositiveButtonColor]];
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
    
    buttonView.frame = CGRectMake(10, 30, 22, 22);
    
    int frameHeight = 44.0f;
    
    [self.signUpView.usernameField setFrame:CGRectMake(20.0f, signUpViewTitle.frame.origin.y + 50, 280.0f, frameHeight)];
    self.signUpView.usernameField.layer.cornerRadius = 3;
    
    [self.signUpView.passwordField setFrame:CGRectMake(20.0f, self.signUpView.usernameField.frame.origin.y + self.signUpView.usernameField.frame.size.height + 20, 280.0f, frameHeight)];
    self.signUpView.passwordField.layer.cornerRadius = 3;
    
    [self.signUpView.additionalField setFrame:CGRectMake(20.0f, self.signUpView.passwordField.frame.origin.y + self.signUpView.passwordField.frame.size.height + 10, 280.0f, frameHeight)];
    self.signUpView.additionalField.layer.cornerRadius = 3;
    
    [self.signUpView.signUpButton setFrame:CGRectMake(20.0f, self.signUpView.additionalField.frame.origin.y + self.signUpView.additionalField.frame.size.height + 40, 280.0f, frameHeight)];
    self.signUpView.signUpButton.layer.cornerRadius = 3;
    self.signUpView.signUpButton.titleLabel.font = [UIFont fontWithName:@"HiraKakuProN-W3" size:16.0f];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) dismisViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
