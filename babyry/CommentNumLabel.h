//
//  CommentNumLabel.h
//  babyry
//
//  Created by Kenji Suzuki on 2015/01/19.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CommentNumLabel : UIView

@property (strong, nonatomic) IBOutlet UILabel *num;

+ (instancetype)view;
- (void)setCommentNumber:(int)number;

@end
