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
#import "TagView.h"

@interface TagEditViewController : UIViewController<UIGestureRecognizerDelegate,TagViewDelegate>

@property PFObject *imageInfo;
@property NSMutableArray *tags;
@property (weak, nonatomic) IBOutlet UIView *tagDisplayView;
@property (strong, nonatomic) IBOutlet UIView *backgroundView;
@property NSMutableDictionary *tagUpateQueue;

- (void)updateTag:(TagView *)tagView;

@end
