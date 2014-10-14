//
//  PartnerWaitViewController.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/09/24.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "PartnerWaitViewController.h"
#import "FamilyRole.h"
#import "PartnerInvitedEntity.h"
#import "Logger.h"
#import "Tutorial.h"
#import "PartnerApply.h"

@interface PartnerWaitViewController ()

@end

@implementation PartnerWaitViewController

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
    
    UITapGestureRecognizer *withdrawGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(withdrawGesture)];
    withdrawGesture.numberOfTapsRequired = 1;
    [_withdrawLabel addGestureRecognizer:withdrawGesture];
    
    _isTimerRunning = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    if (!_tm || ![_tm isValid]) {
        _tm = [NSTimer scheduledTimerWithTimeInterval:5.0f target:self selector:@selector(checkFamilyRole) userInfo:nil repeats:YES];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [_tm invalidate];
}

- (void)checkFamilyRole
{
    if (!_isTimerRunning) {
        _isTimerRunning = YES;
        PartnerInvitedEntity *pie = [PartnerInvitedEntity MR_findFirst];
        if (pie.familyId) {
            PFQuery *familyRole = [PFQuery queryWithClassName:@"FamilyRole"];
            [familyRole whereKey:@"familyId" equalTo:pie.familyId];
            [familyRole getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error){
                if(error){
                    [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in checkFamilyRole : %@", error]];
                    _isTimerRunning = NO;
                    return;
                }
                
                PFUser *user = [PFUser currentUser];
                if ([object[@"chooser"] isEqualToString:user[@"userId"]] || [object[@"uploader"] isEqualToString:user[@"userId"]]) {
                    user[@"familyId"] = pie.familyId;
                    [user save];
                    [Tutorial forwardStageWithNextStage:@"tutorialFinished"];
                    
                    [pie MR_deleteEntity];
                    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
                    
                    [self dismissViewControllerAnimated:YES completion:nil];
                }
                _isTimerRunning = NO;
            }];
        }
    }
}

- (void)withdrawGesture
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"申請を取り下げますか？"
                                                    message:@"申請を取り下げた場合、\n入力済みの承認コードは無効となり\n再度パートナー申請が必要となります。"
                                                   delegate:self
                                          cancelButtonTitle:@"キャンセル"
                                          otherButtonTitles:@"取り下げる", nil
                          ];
    [alert show];
}

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
        {
        }
            break;
        case 1:
        {
            [PartnerApply removeApplyList];
            if ([self.navigationController isViewLoaded]) {
                [self.navigationController popToRootViewControllerAnimated:YES];
            } else {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        }
            break;
    }
}

@end
