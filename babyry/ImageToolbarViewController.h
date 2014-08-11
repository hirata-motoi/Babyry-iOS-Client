//
//  ImageToolbarViewController.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/08/11.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImageToolbarViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIBarButtonItem *imageTrashView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *imageSaveView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *imageCommentView;

@property UIView *commentView;

@end
