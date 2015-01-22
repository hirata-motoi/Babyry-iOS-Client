//
//  ChildProfileIconCell.h
//  babyry
//
//  Created by hirata.motoi on 2015/01/10.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ChildProfileIconCellDelegate <NSObject>

- (void)saveChildProperty:(NSString *)childObjectId withParams:(NSMutableDictionary *)params;
- (void)setTargetChild:(NSString *)childObjectId;
- (void)showIconEditActionSheet:(NSString *)childObjectId;
- (void)closeEditing;

@end

@interface ChildProfileIconCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *childNameLabel;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UITextField *childNameEditField;
@property (weak, nonatomic) IBOutlet UILabel *editLabel;
@property (weak, nonatomic) IBOutlet UIView *iconContainer;
@property NSString *childObjectId;
@property (nonatomic,assign) id<ChildProfileIconCellDelegate> delegate;

- (void)closeEditField;

@end
