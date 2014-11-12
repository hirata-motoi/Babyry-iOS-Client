//
//  PasswordChangeViewController.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/11/01.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "PasswordChangeViewController.h"
#import "Account.h"
#import "Logger.h"
#import "MBProgressHUD.h"
#import "Navigation.h"

@interface PasswordChangeViewController ()

@end

@implementation PasswordChangeViewController
{
    MBProgressHUD *hud;
}

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
    
    _passwordChangeLabel.layer.cornerRadius = 5;
    
    UITapGestureRecognizer *changePasswordGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(changePassword)];
    changePasswordGesture.numberOfTapsRequired = 1;
    [_passwordChangeLabel addGestureRecognizer:changePasswordGesture];
    
    [Navigation setTitle:self.navigationItem withTitle:@"パスワード変更" withSubtitle:nil withFont:nil withFontSize:0 withColor:nil];
    
    [_changePasswordField becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) changePassword
{
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"パスワード保存中";
    
    NSString *errorMessage = [Account checkEmailRegisterFields:@"dummy@aaa.bbb" password:_changePasswordField.text passwordConfirm:_changePasswordConfirmField.text];
    if (![errorMessage isEqualToString:@""]) {
        [hud hide:YES];
        // アラート
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:errorMessage
                                                        message:@""
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"OK", nil
                              ];
        [alert show];
        return;
    }
    
    PFUser *user = [PFUser currentUser];
    user.password = _changePasswordField.text;
    [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error) {
            [Logger writeOneShot:@"cirt" message:[NSString stringWithFormat:@"Error in save password : %@", error]];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ネットワークエラーが発生しました"
                                                            message:@""
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"OK", nil
                                  ];
            [alert show];
            [hud hide:YES];
            return;
        }
        if (succeeded) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"パスワードの変更が完了しました"
                                                            message:@""
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"OK", nil
                                  ];
            [alert show];
            [hud hide:YES];
            [self.navigationController popViewControllerAnimated:YES];
        }
        [hud hide:YES];
    }];
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

@end
