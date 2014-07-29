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
    
    UITapGestureRecognizer *coverViewTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(closeNicknameEdit)];
    coverViewTapGestureRecognizer.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:coverViewTapGestureRecognizer];
    
    // table cell上に透明のformを出す
    _nicknameEditTextField.frame = _nicknameCellRect;
    [_nicknameEditTextField becomeFirstResponder]; // focusをあてる
    
    UIBarButtonItem *button = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonItemStylePlain target:self action:@selector(saveNickname)];
    self.parentViewController.navigationItem.rightBarButtonItem = button;
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
