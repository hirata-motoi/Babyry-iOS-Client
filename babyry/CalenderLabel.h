//
//  CalenderLabel.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/08/07.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CalenderLabel : UIView
@property (strong, nonatomic) IBOutlet UIView *calLabelBack;
@property (strong, nonatomic) IBOutlet UIView *calLabelTop;
@property (strong, nonatomic) IBOutlet UIView *calLabelTopBehind;
@property (strong, nonatomic) IBOutlet UILabel *weekLabel;
@property (strong, nonatomic) IBOutlet UILabel *dateLabel;

+ (instancetype)view;

@end
