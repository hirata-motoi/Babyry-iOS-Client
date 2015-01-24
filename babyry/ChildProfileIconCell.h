//
//  ChildProfileIconCell.h
//  babyry
//
//  Created by hirata.motoi on 2015/01/22.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ChildProfileIconCellDelegate <NSObject>

- (void)showIconEditActionSheet:(NSString *)childObjectId;

@end

@interface ChildProfileIconCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIView *iconContainer;

@property (nonatomic,assign) id<ChildProfileIconCellDelegate> delegate;
@property NSData *imageData;

- (void)setIconImageWithData:(NSData *)imageData;

@end
