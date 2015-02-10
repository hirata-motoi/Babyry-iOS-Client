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
#import "IntroPageRootViewController.h"
#import "CloseButtonView.h"

@interface MyLogInViewController ()
@property (nonatomic, strong) UIImageView *fieldsBackground;
@end

@implementation MyLogInViewController
{
    UILabel *loginViewTitle;
    CloseButtonView *buttonView;
}

@synthesize fieldsBackground;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 背景設定 (ロゴなし)
    [self.logInView setBackgroundColor:[ColorUtils getBabyryColor]];
    [self.logInView setLogo:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@""]]];
    
    // テキストフィールドの背景色
    self.logInView.usernameField.backgroundColor = [ColorUtils getBackgroundColor];
    self.logInView.passwordField.backgroundColor = [ColorUtils getBackgroundColor];
    
    // タイトル
    loginViewTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 50, 320, 44)];
    loginViewTitle.font = [UIFont fontWithName:@"HiraKakuProN-W6" size:20.0f];
    loginViewTitle.textAlignment = NSTextAlignmentCenter;
    loginViewTitle.textColor = [ColorUtils getIntroDarkGrayStringColor];
    loginViewTitle.text = @"ログイン";
    [self.logInView addSubview:loginViewTitle];
    
    // デフォのアイコンがただの×なので変える
    self.logInView.dismissButton.hidden = YES;
    buttonView = [CloseButtonView view];
    [self.logInView addSubview:buttonView];
    UITapGestureRecognizer *dismisGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(dismisViewController)];
    dismisGesture.numberOfTapsRequired = 1;
    [buttonView addGestureRecognizer:dismisGesture];
    
    // ログインボタン設定
    [self.logInView.logInButton setBackgroundColor:[ColorUtils getPositiveButtonColor]];
    [self.logInView.logInButton setBackgroundImage:nil forState:UIControlStateNormal];
    [self.logInView.logInButton setBackgroundImage:nil forState:UIControlStateHighlighted];
    
    [self.logInView.passwordForgottenButton setBackgroundColor:[UIColor clearColor]];
    [self.logInView.passwordForgottenButton setBackgroundImage:nil forState:UIControlStateNormal];
    [self.logInView.passwordForgottenButton setBackgroundImage:nil forState:UIControlStateHighlighted];
    [self.logInView.passwordForgottenButton setTitle:@"パスワードを忘れた方" forState:UIControlStateNormal];
    [self.logInView.passwordForgottenButton setTitle:@"パスワードを忘れた方" forState:UIControlStateHighlighted];
    
    [self.logInView.facebookButton setBackgroundColor:[ColorUtils getFacebookButtonColor]];
    [self.logInView.facebookButton setBackgroundImage:nil forState:UIControlStateNormal];
    [self.logInView.facebookButton setBackgroundImage:nil forState:UIControlStateHighlighted];
    
    // Add login field background
    fieldsBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@""]];
    [self.logInView addSubview:self.fieldsBackground];
    [self.logInView sendSubviewToBack:self.fieldsBackground];
    
    // ユーザー名 text field
    self.logInView.usernameField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"メールアドレス"
                                                                                         attributes:@{NSForegroundColorAttributeName:[ColorUtils getLoginTextFieldPaceHolderColor]}];
    self.logInView.usernameField.keyboardType = UIKeyboardTypeEmailAddress;
    self.logInView.usernameField.font = [UIFont fontWithName:@"HiraKakuProN-W3" size:16.0f];
    
    // パスワード text field
    self.logInView.passwordField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"パスワード"
                                                                                         attributes:@{NSForegroundColorAttributeName:[ColorUtils getLoginTextFieldPaceHolderColor]}];
    self.logInView.passwordField.keyboardType = UIKeyboardTypeASCIICapable;
    self.logInView.passwordField.font = [UIFont fontWithName:@"HiraKakuProN-W3" size:16.0f];
    
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
    
    buttonView.frame = CGRectMake(10, 30, 22, 22);
    
    int frameHeight = 44.0f;
    
    [self.logInView.usernameField setFrame:CGRectMake(20.0f, loginViewTitle.frame.origin.y + 50, 280.0f, frameHeight)];
    self.logInView.usernameField.layer.cornerRadius = 3;
    [self.logInView.passwordField setFrame:CGRectMake(20.0f, self.logInView.usernameField.frame.origin.y + self.logInView.usernameField.frame.size.height + 10, 280.0f, frameHeight)];
    self.logInView.passwordField.layer.cornerRadius = 3;
    
    [self.logInView.logInButton setFrame:CGRectMake(20.0f, self.logInView.passwordField.frame.origin.y + self.logInView.passwordField.frame.size.height + 20, 280.0f, frameHeight)];
    self.logInView.logInButton.layer.cornerRadius = 3;
    self.logInView.logInButton.titleLabel.font = [UIFont fontWithName:@"HiraKakuProN-W3" size:16.0f];
    [self.logInView.passwordForgottenButton setFrame:CGRectMake(35.0f, self.logInView.logInButton.frame.origin.y + self.logInView.logInButton.frame.size.height, 250.0f, 30.0f)];
    self.logInView.passwordForgottenButton.titleLabel.font = [UIFont fontWithName:@"HiraKakuProN-W3" size:14.0f];
    [self.logInView.passwordForgottenButton setTitleColor:[ColorUtils getIntroDarkGrayStringColor] forState:UIControlStateNormal];
    [self.logInView.passwordForgottenButton setTitleColor:[ColorUtils getIntroDarkGrayStringColor] forState:UIControlStateHighlighted];
    
    [self.logInView.facebookButton setFrame:CGRectMake(20.0f, self.logInView.logInButton.frame.origin.y + self.logInView.logInButton.frame.size.height + 50, 280.0f, frameHeight)];
    self.logInView.facebookButton.layer.cornerRadius = 3;
    self.logInView.facebookButton.titleLabel.font = [UIFont fontWithName:@"HiraKakuProN-W3" size:16.0f];
    [self.logInView.facebookButton setImage:nil forState:UIControlStateNormal];
    [self.logInView.facebookButton setImage:nil forState:UIControlStateHighlighted];
     
    NSString *newRegisterText = @"新規登録はこちら";
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:newRegisterText];
    [str addAttribute:NSFontAttributeName
                value:[UIFont fontWithName:@"HiraKakuProN-W3" size:14.0f]
                range:NSMakeRange(0, newRegisterText.length)];
    [str addAttributes:@{NSStrokeColorAttributeName:[ColorUtils getIntroDarkGrayStringColor],
                         NSUnderlineStyleAttributeName:[NSNumber numberWithInteger:NSUnderlineStyleSingle]}
                 range:NSMakeRange(0, newRegisterText.length)];
    UILabel *newRegisterLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, self.logInView.frame.size.height - 20 - 14, 280, 14)];
    [newRegisterLabel setAttributedText:str];
    newRegisterLabel.textAlignment = NSTextAlignmentCenter;
    [self.logInView addSubview:newRegisterLabel];
    newRegisterLabel.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *openRegisterView = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(openRegisterView)];
    openRegisterView.numberOfTapsRequired = 1;
    [newRegisterLabel addGestureRecognizer:openRegisterView];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) openRegisterView
{
    [self dismissViewControllerAnimated:YES completion:^(void){
        [(IntroPageRootViewController *)_introPageRootViewController showRegisterStepCheckView];
    }];
}

- (void) dismisViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
