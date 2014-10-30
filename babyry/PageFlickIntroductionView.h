//
//  PageFlickIntroductionView.h
//  babyry
//
//  Created by hirata.motoi on 2014/10/02.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PageFlickIntroductionView : UIView

@property (weak, nonatomic) IBOutlet UILabel *closeButton;

+ (instancetype)view;
- (void)close;

@end
