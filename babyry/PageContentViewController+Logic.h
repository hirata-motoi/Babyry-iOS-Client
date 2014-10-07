//
//  PageContentViewController+Logic.h
//  babyry
//
//  Created by hirata.motoi on 2014/09/16.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PageContentViewController.h"
#import "TagAlbumCollectionViewCell.h"

@interface PageContentViewController_Logic : NSObject

- (void)setImages;
- (BOOL)isToday:(NSInteger)section withRow:(NSInteger)row;
- (BOOL)withinTwoDay: (NSIndexPath *)indexPath;
- (NSDateComponents *)dateComps;
- (NSDate *)getCollectionViewFirstDay;
- (NSMutableArray *)screenSavedChildImages;
- (NSInteger)currentIndexRowInSavedChildImages:(NSIndexPath *)indexPath;
- (void)getChildImagesWithYear:(NSInteger)year withMonth:(NSInteger)month withReload:(BOOL)reload;
- (BOOL)shouldShowMultiUploadView:(NSIndexPath *)indexPath;
- (BOOL)isNoImage:(NSIndexPath *)indexPath;
- (BOOL)isBestImageFixed:(NSIndexPath *)indexPath;
- (BOOL)forbiddenSelectCell:(NSIndexPath *)indexPath;
- (void)setupHeaderView;
- (void)hideFamilyApplyIntroduceView;

// 循環参照(メモリリーク)が起きるので、弱参照にしないと駄目
@property (weak) PageContentViewController *pageContentViewController;

// 今月と先月のgetChildImagesWithYearを読み込んだフラグ
@property BOOL loadCompletBothMonth;

@end
