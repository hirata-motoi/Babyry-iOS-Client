//
//  ChildFilterViewController.h
//  babyry
//
//  Created by hirata.motoi on 2014/11/05.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <QuartzCore/QuartzCore.h>
#import "ChildFilterListCell.h"

@protocol ChildFilterViewControllerDelegate <NSObject>

- (void)executeAdmit:(NSNumber *)indexNumber withChildFamilyMap:(NSMutableDictionary *)childFamilyMap;

@end

@interface ChildFilterViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, ChildFilterListCellDelegate>
{
    id<ChildFilterViewControllerDelegate>delegate;
}

@property (weak, nonatomic) IBOutlet UILabel *closeButton;
@property (weak, nonatomic) IBOutlet UIButton *submitButton;
@property (weak, nonatomic) IBOutlet UITableView *childListTable;
@property (weak, nonatomic) IBOutlet UIView *backgroundView;

@property (nonatomic, assign) id<ChildFilterViewControllerDelegate> delegate;
@property NSMutableArray *childList;
@property NSNumber *indexNumber;
@property NSString *inviterFamilyId;

- (void)refreshChildListTable:(NSMutableArray *)childList;
- (BOOL)switchSelected:(BOOL)selected withIndexPath:(NSIndexPath *)indexPath;

@end
