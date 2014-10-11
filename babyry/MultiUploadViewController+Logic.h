//
//  MultiUploadViewController+Logic.h
//  babyry
//
//  Created by hirata.motoi on 2014/09/16.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MultiUploadViewController.h"

@interface MultiUploadViewController_Logic : NSObject

@property (weak) MultiUploadViewController *multiUploadViewController;

- (void)showCacheImages;
- (void)disableNotificationHistory;
- (void)updateImagesFromParse;
- (void)updateBestShot;
- (void)createNotificationHistory:(NSString *)type;
- (void)updateBestShotWithChild:(NSMutableDictionary *)childProperty withDate:(NSString *)date;
- (void)prepareForTutorial:(UICollectionViewCell *)cell withIndexPath:(NSIndexPath *)indexPath;
- (void)finalizeSelectBestShot;
- (void)forwardNextTutorial;

@end
