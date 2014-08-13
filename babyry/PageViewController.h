//
//  PageViewController.h
//  babyry
//
//  Created by hirata.motoi on 2014/08/05.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PageContentViewController.h"

@interface PageViewController : UIPageViewController<UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property NSMutableArray *childArray;
@property UIView *tagAlbumOperationView;
@property NSInteger currentPageIndex;
@property PageContentViewController *currentDisplayedPageContentViewController;

- (void)openTagSelectView;
- (NSMutableDictionary *)getYearMonthMap;
- (NSString *)getDisplayedChildObjectId;

@end
