//
//  Badge.h
//  babyry
//
//  Created by hirata.motoi on 2014/08/12.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface Badge : UIView

+ (UIImageView *)badgeViewWithType:(NSString *)type withCount:(NSInteger)count;

@end
