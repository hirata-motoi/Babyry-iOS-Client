//
//  NotEmailVerifiedViewController.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/08/28.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "NotEmailVerifiedViewController.h"
#import "Logger.h"
#import "AWSCommon.h"
#import "AWSSESUtils.h"

@interface NotEmailVerifiedViewController ()

@end

@implementation NotEmailVerifiedViewController

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

    [self setLabel];
    
    _isTimerRunning = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidAppear:(BOOL)animated
{
    if (!_tm || ![_tm isValid]) {
        _tm = [NSTimer scheduledTimerWithTimeInterval:5.0f target:self selector:@selector(checkEmailVerified) userInfo:nil repeats:YES];
        [_tm fire];
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    if(_tm && [_tm isValid]) {
        [_tm invalidate];
    }
}

-(void)setLabel
{
    UITapGestureRecognizer *stgr2 = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(resend)];
    stgr2.numberOfTapsRequired = 1;
    [_resendLabel addGestureRecognizer:stgr2];
}

-(void)checkEmailVerified
{
    if (!_isTimerRunning) {
        _isTimerRunning = YES;
        PFUser *user = [PFUser currentUser];
        [user refreshInBackgroundWithBlock:^(PFObject *object, NSError *error){
            if(error) {
                [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in refresh user in checkEmailVerified : %@", error]];
                _isTimerRunning = NO;
                return;
            }
            
            if ([[user objectForKey:@"emailVerified"] boolValue]) {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
            _isTimerRunning = NO;
        }];
    }
}

- (void)resend
{
    [Logger writeOneShot:@"crit" message:@"Resend email"];

    [AWSSESUtils resendVerifyEmail:[AWSCommon getAWSServiceConfiguration:@"SES"] email:[PFUser currentUser][@"emailCommon"]];
    
    // 再送信をした旨をalertで表示
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"登録されているアドレスへ再度メールを送信しました"
                                                    message:[PFUser currentUser][@"email"]
                                                   delegate:nil
                                          cancelButtonTitle:@"閉じる"
                                          otherButtonTitles:nil
                          ];
    [alert show];
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
