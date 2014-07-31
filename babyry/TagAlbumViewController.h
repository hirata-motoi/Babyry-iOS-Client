//
//  TagAlbumViewController.h
//  babyry
//
//  Created by 平田基 on 2014/07/11.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "TagAlbumPageViewController.h"

@interface TagAlbumViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegate>
@property (weak, nonatomic) IBOutlet UIButton *tagSelectButton;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property int cellHeight;
@property int cellWidth;
@property NSMutableArray *childImages;
@property NSNumber *tagId;
@property NSString *childObjectId;
@property NSString *year;
@property UIView *operationView;
@property UILabel *albumViewPreYearLabel;
@property UILabel *albumViewNextYearLabel;

@end
