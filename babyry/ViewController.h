//
//  ViewController.h
//  babyrydev
//
//  Created by kenjiszk on 2014/05/30.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "PageContentViewController.h"

@interface ViewController : UIViewController <PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate, UIPageViewControllerDataSource>
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addNewChildButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *logoutButton;

- (IBAction)startWalkthrough:(id)sender;

@property (strong, nonatomic) PFObject *currentUser;
@property (strong, nonatomic) UIPageViewController *pageViewController;
@property (strong, nonatomic) NSMutableArray *childArray;
@property (strong, nonatomic) NSArray *childArrayFoundFromParse;

@end
