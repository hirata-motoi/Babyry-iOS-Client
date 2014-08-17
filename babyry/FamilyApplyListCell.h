//
//  FamilyApplyListCell.h
//  babyry
//
//  Created by hirata.motoi on 2014/08/18.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FamilyApplyListCell.h"

@protocol FamilyApplyListCellDelegate <NSObject>
- (void)admit:(NSInteger)index;
@end

@interface FamilyApplyListCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (weak, nonatomic) IBOutlet UIButton *admitButton;
@property NSInteger index;

@property (nonatomic,assign) id<FamilyApplyListCellDelegate> delegate;

@end
