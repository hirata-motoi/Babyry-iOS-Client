//
//  NicknameEditViewController.m
//  babyry
//
//  Created by 平田基 on 2014/07/16.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "NicknameEditViewController.h"

@interface NicknameEditViewController ()

@end

@implementation NicknameEditViewController
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
    
    UITapGestureRecognizer *coverViewTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(closeNicknameEdit)];
    coverViewTapGestureRecognizer.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:coverViewTapGestureRecognizer];
    
    UITapGestureRecognizer *saveLabelTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(saveNickname)];
    saveLabelTapGestureRecognizer.numberOfTapsRequired = 1;
    [_nicknameEditSaveLabel addGestureRecognizer:saveLabelTapGestureRecognizer];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)closeNicknameEdit
{
    [self.view removeFromSuperview];
    [self dismissViewControllerAnimated:YES completion:nil];
    self.parentViewController.navigationItem.rightBarButtonItem = nil;
}

- (void)saveNickname
{
    NSString *nickname = _nicknameEditTextField.text;
    
    // 保存
    PFUser *currentUser = [PFUser currentUser];
    currentUser[@"nickName"] = nickname;
    [currentUser saveInBackground];
    
    // viewを書き換え
    [_delegate changeNickname:nickname];
    
    [self closeNicknameEdit];
}


- (void) makeEditField
{
    // table cell上に透明のformを出す
    _nicknameCellContainer.frame = _nicknameCellRect;
    // textfield高さあわせ
    CGRect frame = _nicknameEditTextField.frame;
    frame.size.height = _nicknameCellRect.size.height;
    _nicknameEditTextField.frame = frame;
    // 保存ラベルの高さあわせ
    frame = _nicknameEditSaveLabel.frame;
    frame.size.height = _nicknameCellRect.size.height;
    _nicknameEditSaveLabel.frame = frame;
    
    [_nicknameEditTextField becomeFirstResponder]; // focusをあてる
    _nicknameEditTextField.text = [PFUser currentUser][@"nickName"];
}

@end
