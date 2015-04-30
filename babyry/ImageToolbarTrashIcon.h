//
//  ImageToolbarTrashIcon.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/08/12.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImageToolbarTrashIcon : UIView

@property (strong, nonatomic) IBOutlet UIImageView *trashIconImage;
@property (strong, nonatomic) IBOutlet UILabel *trashIconLabel;

+ (instancetype)view;

@end
