//
//  PageContentViewController.h
//  babyrydev
//
//  Created by kenjiszk on 2014/06/01.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ICTutorialOverlay.h"

@interface PageContentViewController : UIViewController<UICollectionViewDelegate, UICollectionViewDataSource>
@property (weak, nonatomic) IBOutlet UICollectionView *pageContentCollectionView;

@property NSUInteger pageIndex;
@property (strong, nonatomic) NSArray *childArray;

//くるくる
@property UIActivityIndicatorView *indicator;

@property ICTutorialOverlay *overlay;

@end
