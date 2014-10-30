//
//  InputPinCodeViewController.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/09/19.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "InputPinCodeViewController.h"
#import "Account.h"
#import "ChooseRegisterStepViewController.h"
#import "MBProgressHUD.h"
#import "PartnerInvitedEntity.h"
#import "PartnerApply.h"
#import "CloseButtonView.h"

@interface InputPinCodeViewController ()

@end

@implementation InputPinCodeViewController

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
    
    [self makeDismisButton];
    
    if (_inputForRegisteredUser) {
        _startRegisterButton.text = @"完了";
    }
    
    UITapGestureRecognizer *inputPincodeGstr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(inputPincodeGstr)];
    inputPincodeGstr.numberOfTapsRequired = 1;
    [_startRegisterButton addGestureRecognizer:inputPincodeGstr];
    
    UITapGestureRecognizer *stgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap)];
    stgr.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:stgr];
    
    [_pincodeField becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)makeDismisButton
{
    CloseButtonView *view = [CloseButtonView view];
    CGRect rect = view.frame;
    rect.origin.x = 10;
    rect.origin.y = 30;
    view.frame = rect;
    
    UITapGestureRecognizer *logoutGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(dismisViewController)];
    logoutGesture.numberOfTapsRequired = 1;
    [view addGestureRecognizer:logoutGesture];
    
    [self.view addSubview:view];
}

- (void)dismisViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleSingleTap
{
    [self.view endEditing:YES];
}

- (void)inputPincodeGstr
{
    if(![Account validatePincode:_pincodeField.text]){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"申請コードを確認してください"
                                                        message:@"申請コードは数字6桁です。\n再度ご確認の上ご入力ください。"
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"OK", nil
                              ];
        [alert show];
        return;
    }
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"申請コード確認";
    
    PFQuery *query = [PFQuery queryWithClassName:@"PincodeList"];
    [query whereKey:@"pinCode" equalTo:[NSNumber numberWithInt:[_pincodeField.text intValue]]];
    if ([PFUser currentUser] && [PFUser currentUser][@"familyId"]) {
        [query whereKey:@"familyId" notEqualTo:[PFUser currentUser][@"familyId"]];
    }
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ネットワークエラー"
                                                            message:@"ネットワークエラーが発生しました。\n再度お試しください。"
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"OK", nil
                                  ];
            [alert show];
            [hud hide:YES];
            return;
        }
        
        if ([objects count] < 1) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"申請コードが正しくありません"
                                                            message:@"入力された申請コードが見つかりません。\nコードが正しいかご確認ください。"
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"OK", nil
                                  ];
            [alert show];
            [hud hide:YES];
            return;
        }
        
        [hud hide:YES];
        
        PartnerInvitedEntity *pie = [PartnerInvitedEntity MR_findFirst];
        if (pie) {
            pie.familyId = [objects objectAtIndex:0][@"familyId"];
            pie.inputtedPinCode = [objects objectAtIndex:0][@"pinCode"];
        } else {
            PartnerInvitedEntity *newPie = [PartnerInvitedEntity MR_createEntity];
            newPie.familyId = [objects objectAtIndex:0][@"familyId"];
            newPie.inputtedPinCode = [objects objectAtIndex:0][@"pinCode"];
        }
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
     
        if (!_inputForRegisteredUser) {
            // 招待コード入力のところから会員登録している人
            [self dismissViewControllerAnimated:YES completion:nil];
        } else {
            // 会員登録したあとに招待コードを入力する人
            [PartnerApply registerApplyList];
            [self dismissViewControllerAnimated:YES completion:nil];
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
    }];
}

@end
