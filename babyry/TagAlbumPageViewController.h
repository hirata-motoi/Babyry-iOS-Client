//
//  TagAlbumPageViewController.h
//  babyry
//
//  Created by 平田基 on 2014/07/14.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TagAlbumPageViewController : UIPageViewController

@property NSInteger currentSection;
@property NSInteger currentRow;
@property NSArray * childImages;
@property NSString *childObjectId;
@property NSString *name;
@property NSMutableArray *imageList;
@property NSInteger currentIndex;

@end