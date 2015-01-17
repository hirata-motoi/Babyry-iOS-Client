//
//  ImageSelectToolView.h
//  babyry
//
//  Created by hirata.motoi on 2015/01/09.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ImageSelectToolViewDelegate <NSObject>

- (void)cancel;
- (void)submit;

@end

@interface ImageSelectToolView : UIView
@property (weak, nonatomic) IBOutlet UIButton *submitButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (nonatomic,assign) id<ImageSelectToolViewDelegate> delegate;

+ (instancetype)view;

@end
