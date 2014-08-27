//
//  FamilyApplyViewController.h
//  babyry
//
//  Created by Motoi Hirata on 2014/06/15.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "MBProgressHUD.h"
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

@interface FamilyApplyViewController : UIViewController <ABPeoplePickerNavigationControllerDelegate>

@property (strong, nonatomic) IBOutlet UIView *searchBackContainerView;
@property (weak, nonatomic) IBOutlet UIView *searchContainerView;
@property (weak, nonatomic) IBOutlet UIView *selfUserIdContainer;
@property (strong, nonatomic) IBOutlet UILabel *selfUserEmail;
@property (strong, nonatomic) IBOutlet UIView *inviteContainer;
- (IBAction)inviteByLine:(id)sender;
- (IBAction)inviteByMail:(id)sender;
- (IBAction)searchFromAddressBook:(id)sender;

@property UIButton *messageButton;
@property (nonatomic) PFObject *searchedUserObject;
@property (nonatomic) UITextField *searchForm;
@property NSString *searchingStep;

@property MBProgressHUD *hud;
@property MBProgressHUD *stasusHud;

@property NSTimer *tm;

@property PFObject *familyObject;
@property PFObject *applyObject;

@property NSString *escapedUrlTitle;
@property NSString *escapedUrlText;

@property NSString *pickedAddress;

@end
