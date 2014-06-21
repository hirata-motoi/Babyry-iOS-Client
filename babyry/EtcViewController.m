//
//  EtcViewController.m
//  babyry
//
//  Created by Motoi Hirata on 2014/06/15.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "EtcViewController.h"
#import "FamilyApplyViewController.h"

@interface EtcViewController ()

@end

@implementation EtcViewController

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

    [self.closeEtcModalButton addTarget:self action:@selector(closeEtcModal) forControlEvents:UIControlEventTouchUpInside];
    [self.logoutButton addTarget:self action:@selector(logout) forControlEvents:UIControlEventTouchUpInside];
    [self.familyApplyOpenButton addTarget:self action:@selector(openFamilyApply) forControlEvents:UIControlEventTouchUpInside];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)closeEtcModal
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)logout
{
    [PFUser logOut];
    [self closeEtcModal];
}

- (void)openFamilyApply
{
    FamilyApplyViewController * familyApplyViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"FamilyApplyViewController"];
    [self presentViewController:familyApplyViewController animated:true completion:nil];
}

@end
