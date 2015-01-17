//
//  CellImageFramePlaceHolder.h
//  babyry
//
//  Created by Kenji Suzuki on 2015/01/03.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CalendarCollectionViewCell.h"

@interface CellImageFramePlaceHolder : UIView

+ (instancetype)view;
- (void)setPlaceHolderForCell:(CalendarCollectionViewCell *)cell indexPath:(NSIndexPath *)indexPath role:(NSString *)role candidateCount:(int)candidateCount;

@property (strong, nonatomic) IBOutlet UIImageView *placeHolderIcon;
@property (strong, nonatomic) IBOutlet UILabel *placeHolderLabel;
@property (strong, nonatomic) IBOutlet UIImageView *photoSmileIcon;
@property (strong, nonatomic) IBOutlet UILabel *uploadedNumLabel;
@property (strong, nonatomic) IBOutlet UILabel *uploadMaxNumLabel;

@end
