//
//  TagAlbumOperationViewController.h
//  babyry
//
//  Created by 平田基 on 2014/07/14.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <Parse/Parse.h>

@interface TagAlbumOperationViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIView *tagAlbumOperationView;
@property NSNumber *tagId;
@property NSMutableArray *tags;
@property NSString *holdedBy; // このインスタンスを保持しているインスタンスのクラス
@property NSString *childObjectId;
@property NSString *year;
@property NSDictionary *frameOption;

@end
