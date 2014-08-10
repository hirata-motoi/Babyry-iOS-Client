//
//  CellBackgroundViewToEncourageChoose.h
//  babyry
//
//  Created by hirata.motoi on 2014/08/04.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CellBackgroundViewToEncourageChoose : UIView
@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (strong, nonatomic) IBOutlet UILabel *upCountLabel;

+ (instancetype)view;
@end
