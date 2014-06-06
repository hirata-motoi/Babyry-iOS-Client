//
//  ParseLoginViewController.h
//  babyrydev
//
//  Created by kenjiszk on 2014/06/03.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface ParseLoginViewController : UIViewController <PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate>

- (void)openLoginView;

@end
