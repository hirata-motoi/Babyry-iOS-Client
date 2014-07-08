//
//  MaintenanceViewController.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/07/08.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MaintenanceViewController : UIViewController
@property (strong, nonatomic) IBOutlet UITextView *maintenanceViewTextView;
@property (strong, nonatomic) IBOutlet UIImageView *maintenanceImageView;
- (IBAction)maintenanceReloadButton:(id)sender;

@end
