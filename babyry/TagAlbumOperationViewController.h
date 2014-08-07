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
#import "TagAlbumViewController.h"

@class TagAlbumOperationViewController;
@protocol TagAlbumOperationViewControllerDelegate <NSObject>
- (NSMutableDictionary *)getYearMonthMap;
- (NSString *)getDisplayedChildObjectId;
@end

@interface TagAlbumOperationViewController : UIViewController
{
    id<TagAlbumOperationViewControllerDelegate>delegate;
}
@property (nonatomic,assign) id<TagAlbumOperationViewControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIView *tagAlbumOperationView;
@property NSNumber *tagId;
@property NSMutableArray *tags;
@property NSString *holdedBy; // このインスタンスを保持しているインスタンスのクラス
@property NSString *childObjectId;
@property NSString *year;
@property NSDictionary *frameOption;
@property TagAlbumViewController *tagAlbumViewController;

@end
