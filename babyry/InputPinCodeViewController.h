//
//  InputPinCodeViewController.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/09/19.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface InputPinCodeViewController : UIViewController

@property (strong, nonatomic) IBOutlet UILabel *dismisButton;
@property (strong, nonatomic) IBOutlet UITextField *pincodeField;
@property (strong, nonatomic) IBOutlet UILabel *startRegisterButton;

@end
