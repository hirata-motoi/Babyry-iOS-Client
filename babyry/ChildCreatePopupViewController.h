//
//  ChildCreatePopupViewController.h
//  babyry
//
//  Created by hirata.motoi on 2015/01/25.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ChildPropertyUtils.h"
#import "DatePickerView.h"
#import "ChildProfileIconCell.h"
#import "ChildProfileBirthdayCell.h"
#import "ChildIconCollectionViewController.h"
#import "ChildProfileGenderCell.h"

@protocol ChildCreatePopupViewControllerDelegate <NSObject>

- (id)getParentViewController;
- (void)hidePopup;

@end

@interface ChildCreatePopupViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, ChildPropertyUtilsDelegate, DatePickerViewDelegate, ChildProfileIconCellDelegate, ChildIconCollectionViewControllerDelegate, ChildProfileBirthdayCellDelegate, ChildProfileGenderCellDelegate>

@property (nonatomic, assign)id<ChildCreatePopupViewControllerDelegate>delegate;
@property (weak, nonatomic) IBOutlet UITableView *editTable;
@property (weak, nonatomic) IBOutlet UIButton *submitButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

@end
