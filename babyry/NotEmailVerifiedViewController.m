//
//  NotEmailVerifiedViewController.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/08/28.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "NotEmailVerifiedViewController.h"
#import "Logger.h"

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
    
    // ログアウトラベル
    UILabel *logoutLabel = [[UILabel alloc] init];
    logoutLabel.font = [UIFont systemFontOfSize:12];
    logoutLabel.userInteractionEnabled = YES;
    logoutLabel.textAlignment = NSTextAlignmentCenter;
    logoutLabel.text = @"ログアウト";
    logoutLabel.textColor = [UIColor orangeColor];
    logoutLabel.layer.cornerRadius = 5;
    logoutLabel.layer.borderColor = [UIColor orangeColor].CGColor;
    logoutLabel.layer.borderWidth = 1.0f;
    CGRect frame = CGRectMake(10, 30, 80, 30);
    logoutLabel.frame = frame;
    [self.view addSubview:logoutLabel];
    
    UITapGestureRecognizer *stgr1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(logOut)];
    stgr1.numberOfTapsRequired = 1;
    [logoutLabel addGestureRecognizer:stgr1];
    
    // メール再送信ラベル
    UILabel *resendLabel = [[UILabel alloc]init];
    resendLabel.font = [UIFont systemFontOfSize:18];
    resendLabel.userInteractionEnabled = YES;
    resendLabel.textAlignment = NSTextAlignmentCenter;
    resendLabel.text = @"確認メール再送信";
    resendLabel.textColor = [UIColor orangeColor];
    resendLabel.frame = CGRectMake(self.view.frame.size.width/2 - 180/2, self.view.frame.size.height*2/3 + 75, 180, 44);
    resendLabel.layer.cornerRadius = 5;
    resendLabel.layer.borderColor = [UIColor orangeColor].CGColor;
    resendLabel.layer.borderWidth = 1;
    [self.view addSubview:resendLabel];
    
    UITapGestureRecognizer *stgr2 = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(resend)];
    stgr2.numberOfTapsRequired = 1;
    [resendLabel addGestureRecognizer:stgr2];
    
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

-(void)checkEmailVerified
{
    if (!_isTimerRunning) {
        _isTimerRunning = YES;
        NSLog(@"checkEmailVerified");
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

- (void)logOut
{
    [PFUser logOut];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)resend
{
    [Logger writeOneShot:@"crit" message:@"Resend email"];
    PFUser *selfUser = [PFUser currentUser];
    NSString *email = selfUser[@"email"];
    selfUser[@"email"] = email;
    [selfUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        [[PFUser currentUser]refresh];
    }];
    
    // 再送信をした旨をalertで表示
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"以下のアドレスへ再度メールを送信しました"
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
