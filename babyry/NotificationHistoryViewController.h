//
//  NotificationHistoryViewController.h
//  babyry
//
//  Created by Kenji Suzuki on 2015/01/08.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NotificationHistoryViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UITableView *notificationTableView;
@property (strong, nonatomic) IBOutlet UIButton *allKidokuButton;
- (IBAction)allKidokuButtonAction:(id)sender;

@property NSMutableArray *notificationHistoryArray;

@end
