//
//  FamilyApplyViewController.h
//  babyry
//
//  Created by Motoi Hirata on 2014/06/15.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface FamilyApplyViewController : UIViewController
@property (weak, nonatomic) IBOutlet UISegmentedControl *roleControl;
@property (weak, nonatomic) IBOutlet UIScrollView *searchResultContainer;
@property (weak, nonatomic) IBOutlet UIView *searchContainerView;
@property (weak, nonatomic) IBOutlet UIView *selfUserIdContainer;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *closeFamilyApplyButton;
@property (weak, nonatomic) IBOutlet UILabel *selfUserId;
@property (nonatomic) PFObject *searchedUserObject;
@property (nonatomic) UITextField *searchForm;

@end
