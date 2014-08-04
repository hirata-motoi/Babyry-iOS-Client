//
//  CellBackgroundViewToWaitUpload.h
//  babyry
//
//  Created by hirata.motoi on 2014/08/05.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CellBackgroundViewToWaitUpload : UIView
@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

+ (instancetype)view;
@end
