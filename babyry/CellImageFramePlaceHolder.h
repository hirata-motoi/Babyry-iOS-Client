//
//  CellImageFramePlaceHolder.h
//  babyry
//
//  Created by Kenji Suzuki on 2015/01/03.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CellImageFramePlaceHolder : UIView

+ (instancetype)view;

@property (strong, nonatomic) IBOutlet UILabel *placeHolderLabel;

@end
