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

@interface AlbumViewController : UIViewController<UICollectionViewDelegate, UICollectionViewDataSource>
@property (weak, nonatomic) IBOutlet UICollectionView *albumCollectionView;
- (IBAction)albumBackButton:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *albumViewNameLabel;
- (IBAction)albumViewPreMonthButton:(id)sender;
- (IBAction)albumViewNextMonthButton:(id)sender;

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

@end
