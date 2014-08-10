//
//  ImagePageViewController.h
//  babyry
//
//  Created by hirata.motoi on 2014/07/26.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImagePageViewController : UIPageViewController<UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property NSInteger currentSection;
@property NSInteger currentRow;
@property NSArray * childImages;
@property NSString *childObjectId;
@property NSString *name;
@property NSMutableArray *imageList;
@property NSInteger currentIndex;
@property BOOL showPageNavigation; // headerのsubtitleに何枚中何枚目を出すかどうか
@property NSMutableDictionary *imagesCountDic;
@property NSMutableDictionary *child;

@end
