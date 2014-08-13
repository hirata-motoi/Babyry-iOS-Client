//
//  AcceptableUsePolicyViewController.h
//  babyry
//
//  Created by hirata.motoi on 2014/08/13.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import <Parse/Parse.h>

@interface AcceptableUsePolicyViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property MBProgressHUD *hud;

@end
