//
//  TagView.h
//  babyry
//
//  Created by 平田基 on 2014/07/10.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <QuartzCore/QuartzCore.h>
#import "TagEditViewController.h"

@interface TagView : UIView

+ (TagView *)createTag:(PFObject *)tagInfo attached:(BOOL)attached;
@property NSNumber *tagId;
@property BOOL attached;
@property TagEditViewController *tagEditViewController;

@end
