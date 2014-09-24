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
                    pie.familyId = nil;
                    pie.inputtedPinCode = nil;
                    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
                    [self dismissViewControllerAnimated:YES completion:nil];
                }
                _isTimerRunning = NO;
            }];
        }
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

@end
