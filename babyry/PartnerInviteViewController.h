//
//  PartnerInviteViewController.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/09/16.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface PartnerInviteViewController : UIViewController

@property (strong, nonatomic) IBOutlet UILabel *inviteByLine;
@property (strong, nonatomic) IBOutlet UILabel *inviteByMail;
@property (strong, nonatomic) IBOutlet UILabel *displayedPinCode;
@property (strong, nonatomic) IBOutlet UILabel *inviteAlreadyRegisterdUser;

@property NSNumber *pinCode;
@property int pinCodeSaveRetryMaxCount;
@property int pinCodeSaveRetryCount;

@property NSMutableArray *childProperties;

@end
