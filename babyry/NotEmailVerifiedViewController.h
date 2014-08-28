//
//  NotEmailVerifiedViewController.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/08/28.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface NotEmailVerifiedViewController : UIViewController

@property UIViewController *viewController;
@property NSTimer *tm;
@property BOOL isTimerRunning;

@end
