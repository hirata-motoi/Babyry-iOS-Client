//
//  NicknameEditViewController.m
//  babyry
//
//  Created by 平田基 on 2014/07/16.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ProfileEditViewController.h"
#import "Logger.h"
#import "Account.h"
#import "MBProgressHUD.h"

@interface ProfileEditViewController ()

@end

@implementation ProfileEditViewController

@synthesize delegate = _delegate;

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
    
    [self makeEditField];

    UITapGestureRecognizer *coverViewTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(closeProfileEdit)];
    coverViewTapGestureRecognizer.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:coverViewTapGestureRecognizer];
    
    UITapGestureRecognizer *saveLabelTapGestureRecognizer;
    if ([_profileType isEqualToString:@"nickname"]) {
        saveLabelTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(saveNickname)];
    } else if ([_profileType isEqualToString:@"email"]) {
        saveLabelTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(saveEmail)];
    }
    
    saveLabelTapGestureRecognizer.numberOfTapsRequired = 1;
    [_profileEditSaveLabel addGestureRecognizer:saveLabelTapGestureRecognizer];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)closeProfileEdit
{
    [self.view removeFromSuperview];
    [self dismissViewControllerAnimated:YES completion:nil];
    self.parentViewController.navigationItem.rightBarButtonItem = nil;
}

- (void)saveNickname
{
    NSString *nickname = _profileEditTextField.text;
    
    // 保存
    PFUser *currentUser = [PFUser currentUser];
    currentUser[@"nickName"] = nickname;
    [currentUser saveInBackground];
    
    // viewを書き換え
    [_delegate changeNickname:nickname];
    
    [self closeProfileEdit];
}

- (void)saveEmail
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:NO];
    hud.labelText = @"データ更新中";
    
    NSString *email = _profileEditTextField.text;
    
    PFQuery *emailQuery = [PFQuery queryWithClassName:@"_User"];
    [emailQuery whereKey:@"emailCommon" equalTo:email];
    [emailQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if (error) {
            [hud hide:YES];
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in change email duplicate check in User : %@", error]];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ネットワークエラーが発生しました"
                                                            message:@""
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"OK", nil
                                  ];
            [alert show];
            return;
        }
        if ([objects count] == 0) {
            [hud hide:YES];
            // 重複が無いのでUserを更新
            PFUser *currentUser = [PFUser currentUser];
            currentUser[@"username"] = email;
            currentUser[@"email"] = email;
            currentUser[@"emailCommon"] = email;
            [currentUser saveInBackground];
            // viewを書き換え
            [_delegate changeEmail:email];
            
            // EmailVerifyの既存のデータを削除
            PFQuery *verifyQuery = [PFQuery queryWithClassName:@"EmailVerify"];
            [verifyQuery whereKey:@"userId" equalTo:[PFUser currentUser][@"userId"]];
            [verifyQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
                if ([objects count] > 0) {
                    for (PFObject *object in objects) {
                        [object deleteInBackground];
                    }
                }
                
                // EmailVerifyに入れる
                // emailCommonにあるものを入れていくので基本的に重複チェックはしない
                [Account sendVerifyEmail:email];
            }];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"新しいメールアドレスに認証メールを送信しました"
                                                            message:@"届いたメールに記載されているURLをクリックしてメールアドレス認証を完了してください"
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"OK", nil
                                  ];
            [alert show];
            
            [self closeProfileEdit];
            return;
        }
        if ([objects count] > 0) {
            [hud hide:YES];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"登録済みのアカウントです"
                                                            message:@"もう一度メールアドレスをご確認ください"
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"OK", nil
                                  ];
            [alert show];
            return;
        }
    }];
}


- (void) makeEditField
{
    // table cell上に透明のformを出す
    _profileCellContainer.frame = _profileCellRect;
    // textfield高さあわせ
    CGRect frame = _profileEditTextField.frame;
    frame.size.height = _profileCellRect.size.height;
    _profileEditTextField.frame = frame;
    // 保存ラベルの高さあわせ
    frame = _profileEditSaveLabel.frame;
    frame.size.height = _profileCellRect.size.height;
    _profileEditSaveLabel.frame = frame;
    
    [_profileEditTextField becomeFirstResponder]; // focusをあてる
    
    if ([_profileType isEqualToString:@"nickname"]) {
        _profileEditTextField.text = [PFUser currentUser][@"nickName"];
    } else if ([_profileType isEqualToString:@"email"]) {
        _profileEditTextField.text = [PFUser currentUser][@"emailCommon"];
    }
}

@end
