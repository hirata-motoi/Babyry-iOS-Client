//
//  TagEditViewController.h
//  babyry
//
//  Created by 平田基 on 2014/07/10.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <QuartzCore/QuartzCore.h>

@interface TagEditViewController : UIViewController<UIGestureRecognizerDelegate>

@property PFObject *imageInfo;
@property NSMutableArray *tags;
@property (weak, nonatomic) IBOutlet UIView *tagDisplayView;
@property (strong, nonatomic) IBOutlet UIView *backgroundView;
@property BOOL tagTouchDisabled;

@end
