//
//  ChooseRegisterStepViewController.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/09/11.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <ParseFacebookUtils/PFFacebookUtils.h>
#import "MySignUpViewController.h"

@interface ChooseRegisterStepViewController : UIViewController<PFSignUpViewControllerDelegate>

@property (strong, nonatomic) IBOutlet UILabel *noRegisterButton;
@property (strong, nonatomic) IBOutlet UILabel *registerButton;
@property (strong, nonatomic) IBOutlet UILabel *dismisButton;

@property BOOL isSignUpCompleted;

@end
