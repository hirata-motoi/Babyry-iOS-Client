//
//  ChildProfileBirthdayCell.h
//  babyry
//
//  Created by hirata.motoi on 2015/01/11.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

@protocol ChildProfileBirthdayCellDelegate <NSObject>

- (void)openDatePickerView:(NSString *)childObjectId;

@end

#import <UIKit/UIKit.h>

@interface ChildProfileBirthdayCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *birthdayLabel;
@property NSString *childObjectId;
@property (nonatomic,assign) id<ChildProfileBirthdayCellDelegate> delegate;

@end
