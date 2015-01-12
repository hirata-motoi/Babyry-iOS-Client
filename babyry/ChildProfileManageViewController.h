//
//  ChildProfileManageViewController.h
//  babyry
//
//  Created by hirata.motoi on 2015/01/10.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ChildProfileBirthdayCell.h"
#import "ChildProfileIconCell.h"

@interface ChildProfileManageViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, ChildProfileBirthdayCellDelegate, ChildProfileIconCellDelegate>
@property (weak, nonatomic) IBOutlet UITableView *profileTable;

- (void)openDatePickerView:(NSString *)childObjectId;
- (void)saveChildProperty:(NSString *)childObjectId withParams:(NSMutableDictionary *)params;

@end
