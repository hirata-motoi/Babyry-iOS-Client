//
//  ChildProfileIconAndNameCell.h
//  babyry
//
//  Created by hirata.motoi on 2015/01/10.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ChildProfileIconAndNameCellDelegate <NSObject>

//- (void)saveChildProperty:(NSString *)childObjectId withParams:(NSMutableDictionary *)params;
//- (void)showOverlay;
- (void)setTargetChild:(NSString *)childObjectId;
- (void)showIconEditActionSheet:(NSString *)childObjectId;
- (void)removeChild:(NSString *)childObjectId;
- (void)openActionList:(NSString *)childObjectId withTargetView:(UIView *)view;

@end

@interface ChildProfileIconAndNameCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *childNameLabel;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UITextField *childNameEditField;
@property (weak, nonatomic) IBOutlet UILabel *editLabel;
@property (weak, nonatomic) IBOutlet UIView *iconContainer;
@property (weak, nonatomic) IBOutlet UIImageView *actionListIcon;
@property NSString *childObjectId;
@property (nonatomic,assign) id<ChildProfileIconAndNameCellDelegate> delegate;

- (void)closeEditField;

@end
