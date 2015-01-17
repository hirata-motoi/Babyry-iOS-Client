//
//  MyLogInViewController.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/08/17.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import "IntroPageRootViewController.h"

@interface MyLogInViewController : PFLogInViewController

@property UIViewController *introPageRootViewController;

@end
