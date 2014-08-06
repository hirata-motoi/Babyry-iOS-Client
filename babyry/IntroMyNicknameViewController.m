//
//  IntroMyNicknameViewController.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/07/10.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "IntroMyNicknameViewController.h"

@interface IntroMyNicknameViewController ()

@end

@implementation IntroMyNicknameViewController

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

    _introMyNicknameSendLabel.layer.cornerRadius = _introMyNicknameSendLabel.frame.size.width/2;
    _introMyNicknameSendLabel.layer.borderColor = [UIColor orangeColor].CGColor;
    _introMyNicknameSendLabel.layer.borderWidth = 2.0f;
    _introMyNicknameSendLabel.tag = 2;
    
    UITapGestureRecognizer *stgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    stgr.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:stgr];
    
    UITapGestureRecognizer *stgr2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    stgr2.numberOfTapsRequired = 1;
    [_introMyNicknameSendLabel addGestureRecognizer:stgr2];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    // super
    [super viewWillAppear:animated];
    
    // Start observing
    if (!_keyboradObserving) {
        NSNotificationCenter *center;
        center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [center addObserver:self selector:@selector(keybaordWillHide:) name:UIKeyboardWillHideNotification object:nil];
        _keyboradObserving = YES;
    }
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

- (void)keyboardWillShow:(NSNotification*)notification
{
    //NSLog(@"keyboardWillShow");
    // Get userInfo
    NSDictionary *userInfo;
    userInfo = [notification userInfo];
    
    // Calc overlap of keyboardFrame and textViewFrame
    CGRect keyboardFrame;
    CGRect textViewFrame;
    keyboardFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardFrame = [_editingView.superview convertRect:keyboardFrame fromView:nil];
    textViewFrame = _editingView.frame;
    float overlap;
    overlap = MAX(0.0f, CGRectGetMaxY(textViewFrame) - CGRectGetMinY(keyboardFrame));
    //NSLog(@"overlap %f", overlap);
    
    NSTimeInterval duration;
    UIViewAnimationCurve animationCurve;
    void (^animations)(void);
    duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    animations = ^(void) {
        CGRect viewFrame = _editingView.frame;
        viewFrame.origin.y -= overlap;
        _editingView.frame = viewFrame;
    };
    [UIView animateWithDuration:duration delay:0.0 options:(animationCurve << 16) animations:animations completion:nil];
}

- (void)keybaordWillHide:(NSNotification*)notification
{
    //NSLog(@"keyboardWillHide");
    // Get userInfo
    NSDictionary *userInfo;
    userInfo = [notification userInfo];
    
    CGRect textViewFrame;
    textViewFrame = _editingView.frame;
    //float overlap;
    //overlap = MAX(0.0f, CGRectGetMaxY(_defaultCommentViewRect) - CGRectGetMaxY(textViewFrame));
    //NSLog(@"overlap %f", overlap);
    
    NSTimeInterval duration;
    UIViewAnimationCurve animationCurve;
    void (^animations)(void);
    duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    animations = ^(void) {
        CGRect viewFrame = _editingView.frame;
        viewFrame.origin.y = (self.view.frame.size.height - _editingView.frame.size.height);
        _editingView.frame = viewFrame;
    };
    [UIView animateWithDuration:duration delay:0.0 options:(animationCurve << 16) animations:animations completion:nil];
}

-(void)handleSingleTap:(id) sender
{
    if ([sender view].tag == 2) {
        if (!_introMyNicknameField.text || [_introMyNicknameField.text isEqualToString:@""]) {
            NSLog(@"invalid nickname");
        } else {
            NSLog(@"Set MyNickname %@", _introMyNicknameField.text);
            
            PFObject *user = [PFUser currentUser];
            user[@"nickName"] = _introMyNicknameField.text;
            [user save];

            if ([self.navigationController isViewLoaded]) {
                [self.navigationController popToRootViewControllerAnimated:YES];
            } else {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        }
    } else {
        [self.view endEditing:YES];
    }
}

@end
