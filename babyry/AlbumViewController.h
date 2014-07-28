//
//  AlbumViewController.h
//  babyry
//
//  Created by kenjiszk on 2014/06/16.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "ImageCache.h"
#import "ICTutorialOverlay.h"

@interface AlbumViewController : UIViewController<UICollectionViewDelegate, UICollectionViewDataSource, UIPageViewControllerDataSource>
@property (weak, nonatomic) IBOutlet UICollectionView *albumCollectionView;
@property (weak, nonatomic) IBOutlet UILabel *albumViewNameLabel;

@property NSString *childObjectId;
@property NSString *month;
@property NSString *date;
@property NSString *name;

@property NSString *yyyy;
@property NSString *mm;
@property NSString *dd;

@property float cellWidth;
@property float cellHeight;

@property NSArray *albumImageArray;

@property UILabel *albumViewPreMonthLabel;
@property UILabel *albumViewNextMonthLabel;
@property UILabel *albumViewBackLabel;
@property UILabel *albumViewTagLabel;

@property (strong, nonatomic) UIPageViewController *pageViewController;
@property UIView *tagAlbumOperationView;

@property ICTutorialOverlay *overlay;
@property NSNumber *tutorialStep;

@end
