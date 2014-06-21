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
@property (weak, nonatomic) IBOutlet UIButton *closeFamilyApplyModal;
@property (weak, nonatomic) IBOutlet UILabel *selfUserId;
@property (weak, nonatomic) IBOutlet UITextField *searchForm;
@property (weak, nonatomic) IBOutlet UIButton *searchButton;
@property (nonatomic) PFObject *searchedUserObject;

@end
