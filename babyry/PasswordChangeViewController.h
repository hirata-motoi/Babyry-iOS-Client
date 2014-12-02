//
//  PasswordChangeViewController.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/11/01.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PasswordChangeViewController : UIViewController

@property (strong, nonatomic) IBOutlet UITextField *changePasswordField;
@property (strong, nonatomic) IBOutlet UITextField *changePasswordConfirmField;
@property (strong, nonatomic) IBOutlet UILabel *passwordChangeLabel;

@end
