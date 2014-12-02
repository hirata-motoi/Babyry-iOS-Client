//
//  ChildFilterListCell.h
//  babyry
//
//  Created by hirata.motoi on 2014/11/05.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ChildFilterListCellDelegate <NSObject>

- (BOOL)switchSelected:(BOOL)selected withIndexPath:(NSIndexPath *)indexPath;

@end

@interface ChildFilterListCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UISwitch *selectSwitch;
@property (weak, nonatomic) IBOutlet UILabel *childNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *imageCountLabel;
@property (weak, nonatomic) IBOutlet UIImageView *lastImageView;

@property (nonatomic,assign) id<ChildFilterListCellDelegate> delegate;
@property NSIndexPath *indexPath;

@end
