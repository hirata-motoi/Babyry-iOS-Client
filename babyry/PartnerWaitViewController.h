//
//  PartnerWaitViewController.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/09/24.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PartnerWaitViewController : UIViewController

@property NSTimer *tm;
@property BOOL isTimerRunning;
@property (strong, nonatomic) IBOutlet UILabel *withdrawLabel;

@end
