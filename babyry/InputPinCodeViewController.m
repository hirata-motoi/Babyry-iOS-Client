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
    
    UITapGestureRecognizer *inputPincodeGstr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(inputPincodeGstr)];
    inputPincodeGstr.numberOfTapsRequired = 1;
    [_startRegisterButton addGestureRecognizer:inputPincodeGstr];
    
    UITapGestureRecognizer *stgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap)];
    stgr.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:stgr];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)makeDismisButton
{
    _dismisButton.layer.cornerRadius = _dismisButton.frame.size.width/2;
    UITapGestureRecognizer *dismisViewController = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(dismisViewController)];
    dismisViewController.numberOfTapsRequired = 1;
    [_dismisButton addGestureRecognizer:dismisViewController];
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
    
    PFQuery *query = [PFQuery queryWithClassName:@"PartnerApply"];
    [query whereKey:@"pinCode" equalTo:[NSNumber numberWithInt:[_pincodeField.text intValue]]];
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
        
        PartnerInvitedEntity *pie = [PartnerInvitedEntity MR_createEntity];
        pie.familyId = [objects objectAtIndex:0][@"familyId"];
        pie.inputtedPinCode = [objects objectAtIndex:0][@"pinCode"];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
     
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
}

@end
