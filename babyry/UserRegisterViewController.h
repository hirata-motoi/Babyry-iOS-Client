//
//  UserRegisterViewController.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/09/15.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UserRegisterViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIView *mailAddressRegisterViewContainer;
@property (strong, nonatomic) IBOutlet UITextField *mailAddressField;
@property (strong, nonatomic) IBOutlet UITextField *passwordField;
@property (strong, nonatomic) IBOutlet UITextField *passwordComfirmField;
@property (strong, nonatomic) IBOutlet UILabel *mailAddressRegisterButton;
@property (strong, nonatomic) IBOutlet UILabel *facebookRegisterButton;

@property BOOL keyboradObserving;
@property CGRect defaultCommentViewRect;

@end
