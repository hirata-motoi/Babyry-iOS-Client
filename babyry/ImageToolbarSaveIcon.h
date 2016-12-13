//
//  ImageToolbarSaveIcon.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/08/12.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImageToolbarSaveIcon : UIView

@property (strong, nonatomic) IBOutlet UIImageView *saveIconImage;
@property (strong, nonatomic) IBOutlet UILabel *saveIconLabel;

+ (instancetype)view;

@end
