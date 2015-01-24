//
//  ChildProfileGenderCell.h
//  babyry
//
//  Created by hirata.motoi on 2015/01/10.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GenderSegmentControl.h"

@protocol ChildProfileGenderCellDelegate <NSObject>

- (void)switchGender:(id)sender;

@end

@interface ChildProfileGenderCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *itemNameLabel;
@property (nonatomic, assign)id<ChildProfileGenderCellDelegate>delegate;
@property GenderSegmentControl *segmentControl;

- (void)setupSegmentControl:(NSMutableDictionary *)params;

@end
