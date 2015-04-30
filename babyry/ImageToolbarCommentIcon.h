//
//  ImageToolbarCommentIcon.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/08/12.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImageToolbarCommentIcon : UIView

@property (strong, nonatomic) IBOutlet UIImageView *commentIconImage;
@property (strong, nonatomic) IBOutlet UILabel *commentIconLabel;

+ (instancetype)view;

@end
