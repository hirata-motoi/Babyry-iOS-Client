//
//  ChildProfileManageViewController.h
//  babyry
//
//  Created by hirata.motoi on 2015/01/10.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ChildProfileBirthdayCell.h"
#import "ChildProfileIconAndNameCell.h"
#import "ChildCreatePopupViewController.h"
#import "ChildIconCollectionViewController.h"
#import "ChildProfileGenderCell.h"
                         
@interface ChildProfileManageViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, ChildProfileBirthdayCellDelegate, ChildProfileIconAndNameCellDelegate, ChildCreatePopupViewControllerDelegate, ChildIconCollectionViewControllerDelegate, ChildProfileGenderCellDelegate>
@property (weak, nonatomic) IBOutlet UITableView *profileTable;                                                                                              
@property (weak, nonatomic) IBOutlet UIButton *openChildAddButton;

- (void)openDatePickerView:(NSString *)childObjectId;
//- (void)saveChildProperty:(NSString *)childObjectId withParams:(NSMutableDictionary *)params;

@end
