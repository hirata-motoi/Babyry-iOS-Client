//
//  CalendarCollectionViewCell.h
//  babyry
//
//  Created by 平田基 on 2014/07/14.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CalendarCollectionViewCell : UICollectionViewCell

@property NSInteger currentSection;
@property NSInteger currentRow;
@property BOOL isChoosed;

- (void)rotate;

@end
