//
//  ChildProfileNameCell.h
//  babyry
//
//  Created by hirata.motoi on 2015/01/23.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ChildProfileNameCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UITextField *nameField;

- (void)closeEditField;

@end
